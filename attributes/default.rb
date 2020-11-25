#
# Cookbook:: autopatch_ii
# Attribute:: default
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

default['autopatch_ii']['disable'] = false
default['autopatch_ii']['domain'] = 'example.com'
default['autopatch_ii']['task_username'] = 'SYSTEM'
default['autopatch_ii']['task_frequency'] = :monthly
default['autopatch_ii']['task_frequency_modifier'] = 'THIRD'
default['autopatch_ii']['task_months'] = 'JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV'
default['autopatch_ii']['task_days'] = 'TUE'
default['autopatch_ii']['task_start_time'] = '04:00'
default['autopatch_ii']['desired_timezone_name'] = nil
default['autopatch_ii']['working_dir'] = value_for_platform_family(
  windows: 'C:\chef_autopatch',
  default: '/var/log/chef_autopatch'
)
default['autopatch_ii']['command'] = value_for_platform_family(
  windows: "PowerShell -ExecutionPolicy Bypass -Command \"#{node['autopatch_ii']['working_dir']}\\autopatch.ps1\"",
  default: '/usr/local/sbin/autopatch 2>&1'
)
default['autopatch_ii']['download_install_splay_max_seconds'] = 3600
default['autopatch_ii']['email_notification_mode'] = 'Always'
default['autopatch_ii']['email_to_addresses'] = '"test@example.com"'
default['autopatch_ii']['email_from_address'] = "#{node['hostname']}@example.com"
default['autopatch_ii']['email_smtp_server'] = 'smtp.example.com'
default['autopatch_ii']['auto_reboot_enabled'] = true
default['autopatch_ii']['update_command_options'] = '--skip-broken'

# For windows updates_to_skip is a regex string. All matching updates will be filtered out and not installed.
# . (period) means any character except line break and * (star) means Zero or more times. | (pipe) is OR operator.
# To match multiple updates in the title use something like '.*Malicious.*|.*KB44.*' to match any update with the word Malicious and all updates with KB ID starting with KB44 anywhere in their titles.
# To skip specific KB's just list them with pipes inbetween like 'KB<number>|KB<number>|KB<number>'
#
# For Linux updates_to_skip should be an array of package names not to update
default['autopatch_ii']['updates_to_skip'] = node['os'].include?('windows') ? '' : []

# This attribute is used internally - it should never be set outside the cookbook itself, hence the 'private' designation
default['autopatch_ii']['private_lin_autopatch_disabled_programmatically'] = false
