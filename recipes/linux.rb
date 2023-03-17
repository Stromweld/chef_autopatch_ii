#
# Cookbook:: autopatch_ii
# Recipe:: linux
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

unless node['autopatch_ii']['disabled']
  # Translate the schedule
  # Translate hour and minute
  taskhour, taskminute = node['autopatch_ii']['task_start_time'].split(':')
  case node['autopatch_ii']['task_frequency'] # only :monthly and :weekly are valid.
  when :monthly, 'monthly'
    # When using monthly cycle, autopatch_ii expects a single attribute, node['autopatch_ii']['monthly'], to be set to something like 'third tuesday'.
    # This cookbook's attributes represent that differently, but we can derive it.  Note that some of the edge cases are not supported by cron (linux).
    case node['autopatch_ii']['task_frequency_modifier']
    when 'FIRST', 'SECOND', 'THIRD', 'FOURTH'
      frequency_mod = node['autopatch_ii']['task_frequency_modifier'].downcase
      frequency_day = ''
      # Now gotta find the Day
      begin
        frequency_day = AutoPatchHelper.getLCaseWeekdayFromAbbreviation node['autopatch_ii']['task_days']
      rescue
        raise("autopatch_ii on Linux does not support '#{node['autopatch_ii']['task_days']}' task_days attribute while using ':monthly' task_frequency!! Valid values are MON, TUE, WED, THU, FRI, SAT, SUN")
      end

      # Companies may have a policy to not do patches in December.  cron does not support this notion of skipping a month very easily.
      # We'll work around that here by
      #   1) Disabling autopatch_ii for any month not configured
      #   2) Setting a flag so that we know this automated process disabled it (so we know it is OK to automatically re-enable)
      #   3) Re-enabling once we are in an 'eligible' month.
      unless node['autopatch_ii']['task_months'] == '*'
        if node['autopatch_ii']['task_months'].split(',').include?(DateTime.now.strftime('%^b'))
          # It is a valid month
          # Check if previously disabled
          if node['autopatch_ii']['private_lin_autopatch_disabled_programmatically'] == true
            if node['autopatch_ii']['disable'] == true
              # Re-enable it
              Chef::Log.debug("Re-enabling autopatch_ii for month #{DateTime.now.strftime('%^b')}")
              node.override['autopatch_ii']['disable'] = false
            end
            # Reset our flag
            node.override['autopatch_ii']['private_lin_autopatch_disabled_programmatically'] = false
            Chef::Log.debug('Reset programmatic flag node[\'autopatch_ii\'][\'private_lin_autopatch_disabled_programmatically\'] to false.')
          end
        # It is an invalid month.  Disable autopatch_ii if need be and mark the flag that we did it.
        elsif node['autopatch_ii']['disable'] == false
          node.override['autopatch_ii']['disable'] = true
          node.override['autopatch_ii']['private_lin_autopatch_disabled_programmatically'] = true
          Chef::Log.debug("Disabling autopatch_ii for month #{DateTime.now.strftime('%^b')}!!")
        end
      end
    else
      raise("autopatch_ii on Linux does not support '#{node['autopatch_ii']['task_frequency_modifier']}' task_frequency_modifier attribute!! Valid values are FIRST, SECOND, THIRD, FOURTH")
    end # end task_frequency_modifier
  when :weekly, 'weekly'
    frequency_day = ''
    begin
      frequency_day = AutoPatchHelper.getLCaseWeekdayFromAbbreviation node['autopatch_ii']['task_days']
    rescue
      raise("autopatch_ii on Linux does not support '#{node['autopatch_ii']['task_days']}' task_days attribute while using ':weekly' task_frequency!! Valid values are MON, TUE, WED, THU, FRI, SAT, SUN")
    end
  else
    raise("autopatch_ii on Linux does not support '#{node['autopatch_ii']['task_frequency']}' task_frequency attribute!! Valid values are :monthly, :weekly")
  end
end

# Ensure s-nail is there to send notification emails - it should be, but just in case
package 's-nail'

# Ensure the autopatch.log file is fresh each month and also so it doesn't infinitely grow.
logrotate_app 'chef-autopatch' do
  path "#{node['autopatch_ii']['working_dir']}/autopatch.log"
  options %w(missingok nocompress notifempty)
  frequency 'daily'
  rotate 3
end

next_date = AutoPatch.next_monthly_date(
  "#{frequency_mod} #{frequency_day}",
  taskhour,
  taskminute,
  node['autopatch_ii']['desired_timezone_name']
)
if node['autopatch_ii']['task_frequency'] == :weekly
  hour = next_date.hour
  minute = next_date.min
  month = '*'
  day = '*'
  weekday = AutoPatch.weekday(frequency_day)
  Chef::Log.info("Auto patch scheduled weekly on #{frequency_day} at #{hour}:#{minute}")
elsif node['autopatch_ii']['task_frequency'] == :monthly
  day = next_date.day
  month = next_date.month
  hour = next_date.hour
  minute = next_date.min
  weekday = '*'
  Chef::Log.info("Auto patch scheduled for #{next_date.strftime('%Y-%m-%d')} at #{taskhour}:#{taskminute}")
else
  raise('Missing autopatch_ii :monthly or :weekly specification.')
end

template '/usr/local/sbin/autopatch' do
  source value_for_platform_family(
           debian: 'autopatch_debian.sh.erb',
           default: 'autopatch_rhel.sh.erb'
         )
  owner 'root'
  group 'root'
  mode '0700'
  action :delete if node['autopatch_ii']['disable']
end

cron_d 'autopatch' do
  hour hour
  minute minute
  weekday weekday
  day day
  month month
  command node['autopatch_ii']['command']
  action :delete if node['autopatch_ii']['disable']
end
