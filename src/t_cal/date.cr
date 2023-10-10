require "./time"

# Represents a year, month, and day with no time information.
struct Date
  include Comparable(self)

  getter year : Int32, month : Int32, day : Int32

  # Creates a date from the return of `Time#date`.
  def initialize(date : Tuple(Int32, Int32, Int32))
    @year, @month, @day = date[0], date[1], date[2]
  end

  def <=>(other : self)
    {year, month, day} <=> {other.year, other.month, other.day}
  end

  # See `Time#at_beginning_of_sunday_week`.
  def at_beginning_of_sunday_week : self
    to_time.at_beginning_of_sunday_week.to_date
  end

  # See `Time#day_of_week`.
  def day_of_week : Time::DayOfWeek
    to_time.day_of_week
  end

  # See `Time#shift`.
  def shift(
    years : Int = 0,
    months : Int = 0,
    weeks : Int = 0,
    days : Int = 0
  ) : self
    to_time
      .shift(years: years, months: months, weeks: weeks, days: days)
      .to_date
  end

  # Formats this date as an iCal `DATE` value.
  def to_ical : String
    year.to_s.rjust(4, '0') + month.to_s.rjust(2, '0') + day.to_s.rjust(2, '0')
  end

  # Converts this date to a `Time` at midnight in UTC.
  def to_time : Time
    Time.utc(year, month, day, 0, 0, 0)
  end
end
