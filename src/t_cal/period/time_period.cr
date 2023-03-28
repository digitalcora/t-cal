require "../period"
require "../time"

module TCal
  # An interval between two `Time`.
  struct TimePeriod < Period(Time)
    EARLY_HOUR =  7
    LATE_HOUR  = 22

    # Returns a period that starts and ends at midnight on the same dates as
    # this one. If any part of the end date is covered, the resulting period
    # will cover the entire day, ending at midnight of the next day.
    def all_day : self
      new_end =
        if @end == @end.at_beginning_of_day
          @end
        else
          @end.at_beginning_of_day.shift(days: 1)
        end

      new(@start.at_beginning_of_day, new_end)
    end

    # Iterates over each month in the interval, `#at_beginning_of_month`.
    # Includes the months containing both the start and end of the interval.
    def each_month : Iterator(Time)
      next_time = @start.at_beginning_of_month
      last_time = @end.at_beginning_of_month

      Iterator.of do
        if next_time > last_time
          Iterator.stop
        else
          this_time = next_time
          next_time = next_time.shift(months: 1)
          this_time
        end
      end
    end

    # Iterates over each week in the interval, `#at_beginning_of_sunday_week`.
    # Includes the weeks containing both the start and end of the interval.
    def each_sunday_week : Iterator(Time)
      next_time = @start.at_beginning_of_sunday_week
      last_time = @end.at_beginning_of_sunday_week

      Iterator.of do
        if next_time > last_time
          Iterator.stop
        else
          this_time = next_time
          next_time = next_time.shift(weeks: 1)
          this_time
        end
      end
    end

    # If this period's `start` or `end` fall within the period from `LATE_HOUR`
    # to `EARLY_HOUR`, returns a new period with the offending field(s) set to
    # midnight.
    #
    # If this would result in an empty period, instead returns `self`.
    def snap_to_midnight : self
      new_start, new_end = snap_time(@start), snap_time(@end)

      return self if new_start == new_end
      return self if new_start == @start && new_end == @end

      new(new_start, new_end)
    end

    # Returns the duration of this period.
    def span : Time::Span
      @end - @start
    end

    # Splits this period at day boundaries.
    def split_at_midnight : Array(self)
      next_day = @start.shift(days: 1).at_beginning_of_day

      if @start.date != @end.date && @end != next_day
        [new(@start, next_day)] + new(next_day, @end).split_at_midnight
      else
        [self]
      end
    end

    # Splits this period at Saturday/Sunday boundaries.
    def split_at_sunday : Array(self)
      next_week = @start.shift(weeks: 1).at_beginning_of_sunday_week

      if @start.sunday_week != @end.sunday_week && @end != next_week
        [new(@start, next_week)] + new(next_week, @end).split_at_sunday
      else
        [self]
      end
    end

    # Converts this period to a `DatePeriod`, discarding the time information.
    def to_date_period : DatePeriod
      DatePeriod.new(@start.to_date, @end.to_date)
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
