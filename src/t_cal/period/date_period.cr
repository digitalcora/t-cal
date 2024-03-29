require "../date"
require "../period"

module TCal
  # An interval between two `Date`.
  struct DatePeriod < Period(Date)
    # See `TimePeriod#each_month`.
    def each_month : Iterator(Date)
      to_time_period.each_month.map(&.to_date)
    end

    # See `TimePeriod#each_sunday_week`.
    def each_sunday_week : Iterator(Date)
      to_time_period.each_sunday_week.map(&.to_date)
    end

    # See `TimePeriod#split_at_sunday`.
    def split_at_sunday : Array(self)
      to_time_period.split_at_sunday.map(&.to_date_period)
    end

    # Converts this period to a `TimePeriod` as per `Date#to_time`.
    def to_time_period : TimePeriod
      TimePeriod.new(@start.to_time, @end.to_time)
    end
  end
end
