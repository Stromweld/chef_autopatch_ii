#
# Cookbook:: autopatch_ii
# Recipe:: firstrun_patches
#
# Copyright:: 2020, Corey Hemminger
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

case node['os']
when 'linux'
  # Action is nothing so that normally no action is taken; :run needs to be specifically invoked by lockfile resource
  cmd = value_for_platform_family(
    debian: (<<~EOS
              #{node['autopatch_ii']['updates_to_skip'].empty? ? '' : "apt-mark hold #{node['autopatch_ii']['updates_to_skip']&.to_s}"}
              apt-get update
              apt-get upgrade -y
              apt-get autoremove
              #{node['autopatch_ii']['updates_to_skip'].empty? ? '' : "apt-mark unhold #{node['autopatch_ii']['updates_to_skip']&.to_s}"}
            EOS
            ),
    default: "yum -y upgrade --nogpgcheck #{node['autopatch_ii']['update_command_options']} #{node['autopatch_ii']['updates_to_skip'].each { |skip| "-x #{skip}" } unless node['autopatch_ii']['updates_to_skip'].empty?}"
  )
  execute 'linux-upgrade-once' do
    command cmd
    notifies :request_reboot, 'reboot[firstrun_patches]', :delayed if node['autopatch_ii']['auto_reboot_enabled']
    notifies :create_if_missing, "file[#{Chef::Config[:file_cache_path]}/autopatch.txt]", :immediately
    not_if { ::File.exist?("#{Chef::Config[:file_cache_path]}/autopatch.txt") }
  end

when 'windows'
  powershell_script 'win-update' do
    code <<-EOH
    $reg = "#{node['autopatch_ii']['updates_to_skip']}"
    # Main Logic
    try
    {
      Write-Output "Starting script..."
      $UpdatesToDownload = New-Object -ComObject "Microsoft.Update.UpdateColl"
      $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager" #Support local instance only
      $objSession = New-Object -ComObject "Microsoft.Update.Session" #Support local instance only
      $objSearcher = $objSession.CreateUpdateSearcher()
      $search = "IsInstalled = 0"
      Write-Output "Searching for new updates..."
      try
      {
        $objResults = New-Object -ComObject "Microsoft.Update.UpdateColl"
        $notInstalled = $objSearcher.Search($search)
        foreach ($temp in $notInstalled.Updates)
        {
          if ($reg -eq "")
          {
            $objResults.Add($temp) | Out-Null
          }
          else
          {
            if ($temp.Title -notmatch $reg)
            {
              $objResults.Add($temp) | Out-Null
            }
          }
        }
      }
      catch
      {
        throw "An error occurred while search for updates to be installed."
      } #End Catch

      if ($objResults.Count -eq 0)
      {
        Write-Output "Found $($notInstalled.Updates.Count) new updates."
        Write-Output "Found $($objResults.Count) after filter applied"
        Write-Output "No selected updates found to be installed."
        Exit 0
      }
      else
      {
        # There are updates to be installed.
        Write-Output "Found $($notInstalled.Updates.Count) new updates."
        Write-Output "Found $($objResults.Count) after filter applied."
        foreach ($update in $objResults)
        {
          Write-Output "Update to install '$($update.Title)'"
        }
      }
      # === Download Updates ===
      Write-Output "Starting download of updates..."
      $updDownloader = $objSession.CreateUpdateDownloader()
      $DownloadedUpdateCollection = New-Object -ComObject "Microsoft.Update.UpdateColl"
      foreach ($update in $objResults)
      {
        $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
        $objCollectionTmp.Add($Update) | Out-Null
        $Downloader = $objSession.CreateUpdateDownloader()
        $Downloader.Updates = $objCollectionTmp
        $DownloadResult = $Downloader.Download()
        if(($DownloadResult.ResultCode -eq 2) -and ($($update.EulaAccepted) -eq $true))
        {
          Write-Output "$($update.Title) was successfully downloaded"
          $DownloadedUpdateCollection.Add($Update) | Out-Null
        } #End If $DownloadResult.ResultCode -eq 2 -and $($update.EulaAccepted) -eq $true)
      }

      if ($DownloadedUpdateCollection.Count -eq 0)
      {
        Throw "No updates were downloaded."
      }
      else
      {
        Write-Output "Updates to install:"
        foreach ($update in $DownloadedUpdateCollection)
        {
          Write-Output "$($update.Title)"
        }
      }
      #-==Install Update==-
      Write-Output "Now installing downloaded updates..."
      $NeedsReboot=$false
      $UpdateInstallationReboot = New-Object -ComObject "Microsoft.Update.UpdateColl"
      foreach ($update in $DownloadedUpdateCollection)
      {
        $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
        $objCollectionTmp.Add($Update) | Out-Null
        $objInstaller = $objSession.CreateUpdateInstaller()
        $objInstaller.Updates = $objCollectionTmp
        try
        {
          Write-Output "Trying to install update $($update.Title).."
          $InstallResult = $objInstaller.Install()
        } #End Try
        catch
        {
          throw "Error installing update $($update.Title)."
        } #End Catch

        if ($InstallResult.ResultCode -eq 2)
        {
          Write-Output "Update $($update.Title) installation successfully completed"
          if ($($Update.RebootRequired) -eq $true)
          {
            Write-Output "$($update.Title) requires reboot to be applied."
            $UpdateInstallationReboot.Add($update)
          }
        }
        # if any update from collection require reboot, then mark sign NeedsReboot as true
        if (($NeedsReboot -eq $false) -and ($($Update.RebootRequired) -eq $true))
        {
          $NeedsReboot = $Update.RebootRequired
        }
      }

      if ($UpdateInstallationReboot -ne 0)
      {
        Write-Output "Updates that require reboot to take effect:"
        foreach ($update in $UpdateInstallationReboot)
        {
          Write-Output "$($update.Title)"
        }
      }

      if($NeedsReboot) #checks if any update requires reboot after installation
      {
        $AutoRebootAllowed = $#{node['autopatch_ii']['auto_reboot_enabled']}
        if($AutoRebootAllowed)
        {
          Write-Output "Reboot is required, and Auto reboot is allowed on this machine. Rebooting NOW!"
          Restart-Computer -Force
        } #End If $AutoReboot
        else
        {
          Write-Output "Manual reboot required! AutoReboot is NOT allowed on this machine."
          return "Reboot is required, but not allowed by settings. Please do the reboot manually."
        } #End Else $AutoReboot If $IgnoreReboot
      } #End If $NeedsReboot
      else
      {
        Write-Output "Reboot is not required."
      }
    }
    catch
    {
      Write-Output $Error[0]
      Write-Output ($Error[0].ErrorRecord.Exception | gm)
      Exit 1
    }
    EOH
    ignore_failure true
    live_stream true
    notifies :request_reboot, 'reboot[firstrun_patches]', :delayed if node['autopatch_ii']['auto_reboot_enabled']
    notifies :create_if_missing, "file[#{Chef::Config[:file_cache_path]}/autopatch.txt]", :immediately
    not_if { ::File.exist?("#{Chef::Config[:file_cache_path]}/autopatch.txt") }
  end
else
  raise 'OS unsupported for firstrun_patches recipe'
end

file "#{Chef::Config[:file_cache_path]}/autopatch.txt" do
  content 'First run of patches will only run if this file does not exist.'
  action :nothing
end

reboot 'firstrun_patches' do
  delay_mins 1
  reason 'autopatch_ii::firstrun_patches requested reboot'
  action :nothing
end
