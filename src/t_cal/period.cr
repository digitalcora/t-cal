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

        if last.is_a?(T) && last.end == @start
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
      new_start, new_end = snap_time(@start), snap_time(@end)
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

    private def snap_time(time)
      case time.hour
      when .< EARLY_HOUR then time.at_beginning_of_day
      when .>= LATE_HOUR then time.shift(days: 1).at_beginning_of_day
      else                    time
      end
    end
  end
end
