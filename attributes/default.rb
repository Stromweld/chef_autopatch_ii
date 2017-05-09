#
# Cookbook:: autopatch_ii
# Attribute:: default
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

default['autopatch_ii']['disable'] = false
default['autopatch_ii']['domain'] = 'example.com'
default['autopatch_ii']['task_username'] = 'SYSTEM'
default['autopatch_ii']['task_frequency'] = :monthly
default['autopatch_ii']['task_frequency_modifier'] = 'THIRD'
default['autopatch_ii']['task_months'] = 'JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV'
default['autopatch_ii']['task_days'] = 'TUE'
default['autopatch_ii']['task_start_time'] = '04:00'
default['autopatch_ii']['working_dir'] = node['os'] == 'windows' ? 'C:\chef_autopatch' : '/var/log/chef_autopatch'
default['autopatch_ii']['download_install_splay_max_seconds'] = 3600
default['autopatch_ii']['email_notification_mode'] = 'Always'
default['autopatch_ii']['email_to_addresses'] = '"test@example.com"'
default['autopatch_ii']['email_from_address'] = "#{node['hostname']}@example.com"
default['autopatch_ii']['email_smtp_server'] = 'smtp.example.com'
default['autopatch_ii']['auto_reboot_enabled'] = true
default['autopatch_ii']['updates_to_skip'] = []
default['autopatch_ii']['update_command_options'] = '--skip-broken'

# This attribute is used internally - it should never be set outside the cookbook itself, hence the 'private' designation
default['autopatch_ii']['private_lin_autopatch_disabled_programmatically'] = false
