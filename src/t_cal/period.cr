require "./date_time"

module TCal
  abstract struct Period(T)
    property start : T, end : T

    def initialize(@start, @end)
    end

    def merge_into!(others : Array)
      if others.empty?
        others << self
      else
        last = others.pop

        if last.is_a?(T)
          others << new(last.start, @end)
        else
          others << last << self
        end
      end
    end

    private def new(*args)
      self.class.new(*args)
    end
  end

  struct DatePeriod < Period(Date)
  end

  struct TimePeriod < Period(Time)
    private EARLY_HOUR =  9
    private LATE_HOUR  = 22

    def all_day?
      @start != @end &&
        @start == @start.at_beginning_of_day &&
        @end == @end.at_beginning_of_day
    end

    def snap_to_midnight
      new_start = @start.hour < EARLY_HOUR ? @start.at_beginning_of_day : @start
      new_end = @end.hour >= LATE_HOUR ? @end.at_beginning_of_day : @end

      new_start == @start && new_end == @end ? self : new(new_start, new_end)
    end

    def split_at_midnight
      next_day = @start.shift(days: 1).at_beginning_of_day

      if @start.day != @end.day && @end != next_day
        [new(@start, next_day)] + new(next_day, @end).split_at_midnight
      else
        [self]
      end
    end

    def to_date_period
      DatePeriod.new(@start.to_date, @end.to_date)
    end

    def to_ical
      "#{@start.to_ical}/#{@end.to_ical}"
    end
  end
end
