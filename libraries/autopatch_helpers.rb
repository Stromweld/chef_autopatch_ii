module AutoPatchHelper
  def self.getLCaseWeekdayFromAbbreviation( abbreviatedWeekday )
    case abbreviatedWeekday.downcase
    when "mon"
      return "monday"
    when "tue"
      return "tuesday"
    when "wed"
      return "wednesday"
    when "thu"
      return "thursday"
    when "fri"
      return "friday"
    when "sat"
      return "saturday"
    when "sun"
      return "sunday"
    else
      raise "Could not determine weekday from abbreviation '#{abbreviatedWeekday}'"
    end
  end
end
