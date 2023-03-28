require "./date"

# Additions to the standard library's `Time` module.
struct Time
  # Same as `#at_beginning_of_week` but treats Sunday as the start of the week.
  def at_beginning_of_sunday_week : self
    shift(days: 1).at_beginning_of_week.shift(days: -1)
  end

  # Same as `#calendar_week`, but Sundays are considered part of the following
  # week.
  def sunday_week : {Int32, Int32}
    shift(days: 1).calendar_week
  end

  # Gets the date of this time as a `Date`.
  def to_date : Date
    Date.new(date)
  end

  # Formats this time as an iCal `DATE-TIME` value.
  def to_ical : String
    to_utc.to_s("%Y%m%dT%H%M%SZ")
  end

  enum DayOfWeek
    # Returns the index of this day where 1 is Sunday and 7 is Saturday.
    def sunday_value : Int32
      (value % 7) + 1
    end
  end
end
