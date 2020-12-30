#
# Cookbook:: autopatch_ii
# Library:: autopatch
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

require 'tzinfo'

# autopatch_ii helper logic
# Chef class
class Chef
  # Chef::Recipe class
  class Recipe
    # Chef::Recipe::AutoPatch class
    class AutoPatch
      WEEKS = %w(first second third fourth).freeze unless defined?(WEEKS)
      WEEKDAYS = %w(sunday monday tuesday wednesday thursday friday saturday).freeze unless defined?(WEEKDAYS)

      def self.monthly_day(year, month, monthly_specifier)
        week, weekly_specifier = monthly_specifier.split(' ')
        week.downcase!
        weekly_specifier.downcase!
        raise('Unknown week specified.') unless WEEKS.include?(week)

        first_day_occurance = 1
        first_day_occurance += 1 while weekday(weekly_specifier) != Time.new(year, month, first_day_occurance).wday
        first_day_occurance + (WEEKS.index(week) * 7)
      end

      def self.next_monthly_date(monthly_specifier, hour, minute, time_zone_name)
        desired_tz_offset = if time_zone_name
                              TZInfo::Timezone.get(time_zone_name).current_period.utc_total_offset
                            else
                              Time.now.utc_offset
                            end
        current_tz_offset = Time.now.utc_offset

        current_time_in_dtz = Time.now.utc + desired_tz_offset

        current_patch_time_in_dtz = Time.new(
          current_time_in_dtz.year,
          current_time_in_dtz.month,
          monthly_day(current_time_in_dtz.year, current_time_in_dtz.month, monthly_specifier),
          hour,
          minute,
          0,
          desired_tz_offset
        )

        target_patch_time = if current_time_in_dtz > current_patch_time_in_dtz
                              new_year = current_time_in_dtz.month == 12 ? current_time_in_dtz.year + 1 : current_time_in_dtz.year
                              new_month = current_time_in_dtz.month == 12 ? 1 : current_time_in_dtz.month + 1
                              Time.new(
                                new_year,
                                new_month,
                                monthly_day(new_year, new_month, monthly_specifier),
                                hour,
                                minute,
                                0,
                                desired_tz_offset
                              )
                            else
                              current_patch_time_in_dtz
                            end

        target_patch_time.utc + current_tz_offset
      end

      def self.weekday(weekly_specifier)
        raise('Unknown weekday specified.') unless WEEKDAYS.include?(weekly_specifier)
        WEEKDAYS.index(weekly_specifier)
      end
    end
  end
end
