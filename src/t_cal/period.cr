module TCal
  # An interval between two points of the same type.
  abstract struct Period(T)
    getter start : T, end : T

    class EmptyPeriod < Exception
    end

    class InvalidPeriod < Exception
    end

    def initialize(@start : T, @end : T)
      if @start == @end
        raise EmptyPeriod.new("#{@start.inspect} == #{@end.inspect}")
      end

      if @end < @start
        raise InvalidPeriod.new("#{@end.inspect} < #{@start.inspect}")
      end
    end

    # Returns a copy of the given array where consecutive periods of the same
    # type that are contiguous or overlapping are merged together.
    def self.merge(periods : Array(U)) : Array(U) forall U
      periods.reduce([] of typeof(periods[0])) do |acc, elem|
        elem.is_a?(self) ? elem.merge_into!(acc) : acc << elem
      end
    end

    protected def merge_into!(others : Array)
      if others.empty?
        others << self
      else
        last = others.pop

        if last.is_a?(Period(T)) && last.end >= @start
          others << new({@start, last.start}.min, {@end, last.end}.max)
        else
          others << last << self
        end
      end
    end

    private def new(*args)
      self.class.new(*args)
    end
  end
end
