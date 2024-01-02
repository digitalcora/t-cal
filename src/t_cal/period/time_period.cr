require "../period"
require "../time"

module TCal
  # An interval between two `Time`.
  struct TimePeriod < Period(Time)
    EARLY_HOUR =  7
    LATE_HOUR  = 22

    # Extends this period to span the entirety of all days it spans.
    def all_day : self
      new_end =
        if @end == @end.at_beginning_of_day
          @end
        else
          @end.at_beginning_of_day.shift(days: 1)
        end

      new(@start.at_beginning_of_day, new_end)
    end

    # Extends this period to span the entirety of all months it spans.
    def all_month : self
      new_end =
        if @end == @end.at_beginning_of_month
          @end
        else
          @end.at_beginning_of_month.shift(months: 1)
        end

      new(@start.at_beginning_of_month, new_end)
    end

    # Returns whether this period spans the entirety of all months it spans
    # (`self == self.all_month`).
    def all_month? : Bool
      @start == @start.at_beginning_of_month &&
        @end == @end.at_beginning_of_month
    end

    # Iterates over each month in the interval, `#at_beginning_of_month`.
    # Includes the months containing both the start and end of the interval.
    # Note since the end time is exclusive, if it is exactly at the beginning
    # of a month, that month will not be included.
    def each_month : Iterator(Time)
      next_time = @start.at_beginning_of_month
      last_time = @end.at_beginning_of_month

      if last_time == @end
        last_time = last_time.shift(months: -1)
      end

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
    # Note since the end time is exclusive, if it is exactly at the beginning
    # of a week, that week will not be included.
    def each_sunday_week : Iterator(Time)
      next_time = @start.at_beginning_of_sunday_week
      last_time = @end.at_beginning_of_sunday_week

      if last_time == @end
        last_time = last_time.shift(weeks: -1)
      end

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

    # Splits this period at Saturday/Sunday boundaries.
    def split_at_sunday : Array(self)
      next_week = @start.shift(weeks: 1).at_beginning_of_sunday_week

      if @start.sunday_week != @end.sunday_week && @end != next_week
        [new(@start, next_week)] + new(next_week, @end).split_at_sunday
      else
        [self]
      end
    end

    # Splits this period at month boundaries.
    def split_by_month : Array(self)
      next_month = @start.shift(months: 1).at_beginning_of_month

      if @start.month != @end.month && @end != next_month
        [new(@start, next_month)] + new(next_month, @end).split_by_month
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
