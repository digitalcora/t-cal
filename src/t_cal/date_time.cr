# Additions to the standard library's `Time` module.
struct Time
  # Gets the date of this time as a `Date`.
  def to_date : Date
    Date.new(date)
  end

  # Formats this time as an iCal `DATE-TIME` value.
  def to_ical : String
    to_utc.to_s("%Y%m%dT%H%M%SZ")
  end

  # Returns an iCal property with the given name and this time as its value.
  def to_ical(prop : String) : String
    "#{prop}:#{to_ical}"
  end
end

# Represents a year, month, and day with no time information.
struct Date
  getter year : Int32, month : Int32, day : Int32

  # Creates a date from the return of `Time#date`.
  def initialize(date : Tuple(Int32, Int32, Int32))
    @year, @month, @day = date[0], date[1], date[2]
  end

  # Formats this date as an iCal `DATE` value.
  def to_ical : String
    year.to_s.rjust(4, '0') + month.to_s.rjust(2, '0') + day.to_s.rjust(2, '0')
  end

  # Returns an iCal property with the given name and this date as its value.
  def to_ical(prop : String) : String
    "#{prop};VALUE=DATE:#{to_ical}"
  end

  # Returns the Unix time of this date at midnight in UTC.
  def to_unix : Int64
    Time.utc(year, month, day, 0, 0, 0).to_unix
  end
end
