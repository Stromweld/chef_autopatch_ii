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
    default: "yum -y upgrade --nogpgcheck #{node['autopatch_ii']['update_command_options']} #{node['autopatch_ii']['updates_to_skip']&.each { |skip| join('-x ', skip) } unless node['autopatch_ii']['updates_to_skip'].empty?}"
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
    $Criteria = "IsInstalled=0"
    $Searcher = New-Object -ComObject Microsoft.Update.Searcher
    Write-Output "Searching for updates."
    try
    {
      $SearchResult = $Searcher.Search($Criteria).Updates
      if ($SearchResult.Count -eq 0)
      {
        Write-Output "There are no applicable updates."
        Exit 0
      }
      else
      {
        Write-Output "Found $($SearchResult.Count) updates."
        Write-Output "Applying filter."
        $Updates = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($temp in $SearchResult)
        {
          if ($reg -eq "")
          {
            $Updates.Add($temp) | out-null
          }
          else
          {
            if ($temp.Title -notmatch $reg)
            {
              $Updates.Add($temp) | out-null
            }
          }
        }
	      if ($Updates.Count -eq 0)
        {
          Write-Output "After filter applied there are no applicable updates to install."
          Exit 0
        }
        else
        {
          Write-Output "$($Updates.Count) Updates left to install after filter applied."
          foreach ($temp in $Updates)
          {
            Write-Output $temp.Title
          }
        }
        Write-Output "Downloading Updates."
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Downloader = $Session.CreateUpdateDownloader()
        $Downloader.Updates = $Updates
        $Downloader.Download()
        Write-Output "Installing Updates."
        $Installer = New-Object -ComObject Microsoft.Update.Installer
        $Installer.Updates = $Updates
        $Result = $Installer.Install()
      }
    }
    catch
    {
      Write-Output "Something went wrong during update process."
      Write-Error ($_.Exception | Format-List -Force | Out-String) -ErrorAction Continue
      Write-Error ($_.InvocationInfo | Format-List -Force | Out-String) -ErrorAction Continue
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
