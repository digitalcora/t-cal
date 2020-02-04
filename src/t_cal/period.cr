require "./date_time"

module TCal
  # An interval between two points of the same type.
  abstract struct Period(T)
    getter start : T, end : T

    def initialize(@start : T, @end : T)
    end

    # Appends this period to an array, merging contiguous periods.
    #
    # If the last item in the array is a period of the same type as this one,
    # and has an `end` equal to this period's `start`, it will be replaced with
    # a new period that covers the interval of both periods combined. Otherwise
    # this period is simply appended to the array.
    def merge_into!(others : Array) : Array
      if others.empty?
        others << self
      else
        last = others.pop

        if last.is_a?(Period(T)) && last.end == @start
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

  # An interval between two `Date`.
  struct DatePeriod < Period(Date)
  end

  # An interval between two `Time`.
  struct TimePeriod < Period(Time)
    EARLY_HOUR =  9
    LATE_HOUR  = 22

    # Returns `true` if this period starts and ends on day boundaries.
    def all_day? : Bool
      @start != @end &&
        @start == @start.at_beginning_of_day &&
        @end == @end.at_beginning_of_day
    end

    # If this period's `start` or `end` fall within the period from `LATE_HOUR`
    # to `EARLY_HOUR`, returns a new period with the offending field(s) set to
    # midnight.
    def snap_to_midnight : self
      new_start, new_end = snap_time(@start), snap_time(@end)
      new_start == @start && new_end == @end ? self : new(new_start, new_end)
    end

    # Splits this period at day boundaries.
    def split_at_midnight : Array(self)
      next_day = @start.shift(days: 1).at_beginning_of_day

      if @start.day != @end.day && @end != next_day
        [new(@start, next_day)] + new(next_day, @end).split_at_midnight
      else
        [self]
      end
    end

    # Converts this period to a `DatePeriod`, discarding the time information.
    def to_date_period : DatePeriod
      DatePeriod.new(@start.to_date, @end.to_date)
    end

    # Formats this period as an iCal `PERIOD` value.
    def to_ical : String
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
