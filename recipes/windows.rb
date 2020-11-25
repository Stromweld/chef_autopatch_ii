#
# Cookbook:: autopatch_ii
# Recipe:: windows
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

::Chef::DSL::Recipe.include AutoPatchHelper

template 'AutoPatch PowerShell Script' do
  source 'autopatch.ps1.erb'
  path "#{node['autopatch_ii']['working_dir']}\\autopatch.ps1"
  action :delete if node['autopatch_ii']['disable']
end

windows_task 'autopatch' do
  user node['autopatch_ii']['task_username']
  frequency node['autopatch_ii']['task_frequency']
  frequency_modifier node['autopatch_ii']['task_frequency_modifier']
  day node['autopatch_ii']['task_days']
  months node['autopatch_ii']['task_months']
  start_time node['autopatch_ii']['task_start_time']
  cwd 'C:'
  command "PowerShell -ExecutionPolicy Bypass -Command \"#{node['autopatch_ii']['working_dir']}\\autopatch.ps1\""
  action :delete if node['autopatch_ii']['disable']
end
