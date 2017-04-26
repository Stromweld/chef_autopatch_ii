[![Chef cookbook](https://img.shields.io/cookbook/v/autopatch_ii.svg)]()
[![Code Climate](https://codeclimate.com/github/Stromweld/autopatch_ii/badges/gpa.svg)](https://codeclimate.com/github/Stromweld/autopatch_ii)
[![Issue Count](https://codeclimate.com/github/Stromweld/autopatch_ii/badges/issue_count.svg)](https://codeclimate.com/github/Stromweld/autopatch_ii)

# autopatch_ii

## Description

Chef Cookbook for automatically patching nodes on a specific schedule (weekday, hour, and minute). Handles weekly or monthly patching routines with or without node splay for large environments.

Much of this code was copied from chef cookbook auto-patch written by Brian Flad. I've modified it to work with windows and use windows more flexible task scheduling with some magic to get it to also work with linux cron.

## Requirements

### Platforms

* RHEL based platforms
* Windows

### Cookbooks

* cron
* logrotate

## Attributes

| Attribute | Default | Comment |
| -------------  | -------------  | -------------  |
| ['autopatch_ii']['disable'] | false | Boolean, enable or disable patches |
| ['autopatch_ii']['domain'] | 'example.com' | String, Domain server resides in |
| ['autopatch_ii']['task_username'] | 'SYSTEM' | String, Used only for winows task scheduling |
| ['autopatch_ii']['task_frequency'] | :monthly | Symbol, one of either :monthly or :weekly |
| ['autopatch_ii']['task_frequency_modifier'] | 'THIRD' | String, used to denote which week of the month you want to run the task |
| ['autopatch_ii']['task_months'] | 'JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV' | String, CSV list of short names for months you want the task to run in, * is used for all months |
| ['autopatch_ii']['task_days'] | 'TUE' | String, which days of the week in short form you want the task to run on |
| ['autopatch_ii']['task_start_time'] | '04:00' | String, Military time setting for when to run patches |
| ['autopatch_ii']['working_dir'] | node['os'] == 'windows' ? 'C:\chef_autopatch' : '/var/log/chef_autopatch' | String, Directory for log file and temp files |
| ['autopatch_ii']['download_install_splay_max_seconds'] | 3600 | Integer, Max allowed random time to wait before downloading and installing patches, this way we don't overwhelm on premise patch repo |
| ['autopatch_ii']['email_notification_mode'] | 'Always' | String, whether to send email after patches and before reboot with status of patch install |
| ['autopatch_ii']['email_to_addresses'] | '"test@example.com"' | String, email address for nodes to send the email to |
| ['autopatch_ii']['email_from_address'] | "#{node['hostname']}@example.com" | String, email address the email came from |
| ['autopatch_ii']['email_smtp_server'] | 'smtp.example.com' | String, email server to forward the email to, relay with no authentication is recommended |
| ['autopatch_ii']['auto_reboot_enabled'] | true | Boolean, to reboot the server automatically after patches have been installed or to leave it for manual reboot |
| ['autopatch_ii']['updates_to_skip'] | [] | Array of Strings, package names to skip during patches on linux |
| ['autopatch_ii']['update_command_options'] | '' | String, any additional options to be passed to the yum command on linux |
| ['autopatch_ii']['private_lin_autopatch_disabled_programmatically'] | false | Boolean, DO NOT MODIFY THIS, this is modified programatically based on if cron job should skip this month or not |

## Recipes

* `recipe[autopatch_ii]` configures automatic patching and patches server on first chef-client run
* `recipe[autopatch_ii::firstrun_patches]` creates a lock file and runs patches for the first time, afterwards doesn't run as long as lock file exists on the filesystem.
* `recipe[autopatch_ii::linux]` creates cron job and sets up autopatch scripts
* `recipe[autopatch_ii::windows]` creates windows task and sets up autopatch scripts

## Usage

* Change any attributes to fit your patching cycle
* Add `recipe[autopatch_ii]` to your node's run list

### Weekly automatic patching

Just use the `node["autopatch_ii"]['task_frequency'] = :weekly` attribute to override the monthly setting.

### Automatic patching of large numbers of nodes

If you're auto patching many nodes at once, you can optionally modify the splay to prevent denial of service against your network, update server(s), and resources:

* Adding `node["autopatch_ii"]["splay"]`

### Using roles to specify auto patching groups

If you'd like to specify groups of nodes for auto patching, you can setup roles.

Say you want to auto patch some nodes at 8am and some at 10pm on your monthly
"patch day" of the fourth Wednesday every month.

If you have a base role (you do, right?), you can save duplicating attributes
and specify some base information first:

    "autopatch_ii" => {
      "task_frequency" => :weekly,
      "task_days" => 'TUE'
    }

Example role that then could be added to 8am nodes:

    name "autopatch-0800"
    description "Role for automatically patching nodes at 8am on patch day."
    default_attributes(
      "autopatch_ii" => {
        "task_start_time" => '08:00'
      }
    )
    run_list(
      "recipe[autopatch_ii]"
    )

Example role that then could be added to 10pm nodes:

    name "autopatch-2200"
    description "Role for automatically patching nodes at 10pm on patch day."
    default_attributes(
      "autopatch_ii" => {
        "task_start_time" => '22:00'
      }
    )
    run_list(
      "recipe[autopatch_ii]"
    )

### Disabling automatic patching

* Specify `node["autopatch_ii"]["disable"]` to true
* Run chef-client on your node

## License and Author

Author:: Brian Flad (<bflad417@gmail.com>)

Author:: Corey Hemminger (<hemminger@hotmail.com>)

Copyright:: 2017

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
