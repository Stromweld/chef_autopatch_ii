#
# Cookbook:: autopatch_ii
# Recipe:: firstrun_patches
#
# Copyright:: 2017, Corey Hemminger
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
  execute 'linux-upgrade-once' do
    command "yum -y upgrade --nogpgcheck #{node['autopatch_ii']['update_command_options']} #{node['autopatch_ii']['updates_to_skip'].each { |skip| "-x #{skip}" } unless node['autopatch_ii']['updates_to_skip'].empty?}"
    action :nothing
    notifies :request_reboot, 'reboot[firstrun_patches]', :delayed
  end
when 'windows'
  powershell_script 'win-update' do
    code <<-EOH
    Function WSUSUpdate {
      $Criteria = "IsInstalled=0 and Type='Software'"
      $Searcher = New-Object -ComObject Microsoft.Update.Searcher
      try {
        $SearchResult = $Searcher.Search($Criteria).Updates
        if ($SearchResult.Count -eq 0) {
          Write-Output "There are no applicable updates."
          exit
        }
        else {
          $Session = New-Object -ComObject Microsoft.Update.Session
          $Downloader = $Session.CreateUpdateDownloader()
          $Downloader.Updates = $SearchResult
          $Downloader.Download()
          $Installer = New-Object -ComObject Microsoft.Update.Installer
          $Installer.Updates = $SearchResult
          $Result = $Installer.Install()
        }
      }
      catch {
        Write-Output "There are no applicable updates."
      }
    }

    WSUSUpdate
    If ($Result.rebootRequired) { Restart-Computer }
    EOH
    action :nothing
    ignore_failure true
    notifies :request_reboot, 'reboot[firstrun_patches]', :delayed
  end
else
  raise 'OS unsupported for firstrun_patches recipe'
end

file "#{Chef::Config[:file_cache_path]}/autopatch.txt" do
  content 'First run of patches will only run if this file exists.'
  action :create_if_missing
  notifies :run, node['os'] == 'windows' ? 'powershell_script[win-update]' : 'execute[linux-upgrade-once]', :immediately
end

reboot 'firstrun_patches' do
  delay_mins 1
  reason 'autopatch_ii::firstrun_patches requested reboot'
  action :nothing
end
