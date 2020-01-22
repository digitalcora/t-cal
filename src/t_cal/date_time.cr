struct Time
  # NB: Reopening core struct

  def to_date
    Date.new(date)
  end

  def to_ical
    to_utc.to_s("%Y%m%dT%H%M%SZ")
  end

  def to_ical(tag)
    "#{tag}:#{to_ical}"
  end
end

struct Date
  getter year : Int32, month : Int32, day : Int32

  def initialize(date : Tuple(Int32, Int32, Int32))
    @year, @month, @day = date[0], date[1], date[2]
  end

  def to_ical
    year.to_s.rjust(4, '0') + month.to_s.rjust(2, '0') + day.to_s.rjust(2, '0')
  end

  def to_ical(tag)
    "#{tag};VALUE=DATE:#{to_ical}"
  end

  def to_unix
    Time.utc(year, month, day, 0, 0, 0).to_unix
  end
end
