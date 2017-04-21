#
# Cookbook:: autopatch_ii
# Library:: autopatch_helpers
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

# Module to translate short name to full name
module AutoPatchHelper
  def self.getLCaseWeekdayFromAbbreviation(abbreviatedWeekday)
    case abbreviatedWeekday.downcase
    when 'mon'
      'monday'
    when 'tue'
      'tuesday'
    when 'wed'
      'wednesday'
    when 'thu'
      'thursday'
    when 'fri'
      'friday'
    when 'sat'
      'saturday'
    when 'sun'
      'sunday'
    else
      raise "Could not determine weekday from abbreviation '#{abbreviatedWeekday}'"
    end
  end
end
