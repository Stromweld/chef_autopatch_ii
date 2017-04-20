#
# Cookbook:: autopatch_ii
# Recipe:: default
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

directory 'Auto Patch Working Directory' do
  path node['autopatch_ii']['working_dir']
  action :create
end

include_recipe 'autopatch_ii::firstrun_patches'
include_recipe node['os'] == 'windows' ? 'autopatch_ii::windows' : 'autopatch_ii::linux'
