require "./json_api"

class TCal::Calendar
  @alerts : Array(TCal::JSONAPI::Alert)

  private EFFECTS = %w(SHUTTLE SUSPENSION)
  private VERSION = 1 # Increment to invalidate existing UIDs

  def initialize(alerts, @compat_mode : Bool)
    @alerts = alerts.select do |alert|
      EFFECTS.includes?(alert.effect) && alert.definite_active_periods.any?
    end
  end

  def to_s(io)
    io.puts "BEGIN:VCALENDAR"
    io.puts "VERSION:2.0"
    io.puts "PRODID:-//TCal//NONSGML MBTA Shuttles Calendar//EN"
    io.puts "X-WR-CALNAME:MBTA Shuttles"
    @compat_mode ? output_compat_events(io) : output_events(io)
    io.puts "END:VCALENDAR"
  end

  private def output_events(io)
    @alerts.each do |alert|
      io.puts "BEGIN:VEVENT"
      io.puts "UID:tcal-v#{VERSION}-#{alert.id}"
      io.puts "SEQUENCE:#{alert.updated_at.to_unix}"
      io.puts "SUMMARY:#{alert.service_effect}"
      io.puts "DESCRIPTION:#{alert.header}"
      io.puts "URL:#{alert.url}" if !alert.url.nil?
      io.puts "DTSTAMP:#{format_time(alert.updated_at)}"

      periods = condense_periods(alert.definite_active_periods)
      io.puts format_prop("DTSTART", periods.first.start)
      io.puts format_prop("DTEND", periods.first.end)

      if periods.size > 1
        recurrences = periods.skip(1).map do |period|
          "#{format_time(period.start)}/#{format_time(period.end)}"
        end
        io.puts "RDATE;VALUE=PERIOD:#{recurrences.join(",")}"
      end

      io.puts "END:VEVENT"
    end
  end

  private def output_compat_events(io)
    @alerts.each do |alert|
      compat_periods(alert.definite_active_periods).each do |period|
        io.puts "BEGIN:VEVENT"
        io.puts "UID:tcal-v#{VERSION}-#{alert.id}-#{to_unix(period.start)}"
        io.puts "SEQUENCE:#{alert.updated_at.to_unix}"
        io.puts "SUMMARY:#{alert.service_effect}"
        io.puts "DESCRIPTION:#{alert.header}"
        io.puts "URL:#{alert.url}" if !alert.url.nil?
        io.puts "DTSTAMP:#{format_time(alert.updated_at)}"
        io.puts format_prop("DTSTART", period.start)
        io.puts format_prop("DTEND", period.end) if period.start != period.end
        io.puts "END:VEVENT"
      end
    end
  end

  private alias Date = Tuple(Int32, Int32, Int32)
  private record DatePeriod, start : Date, end : Date
  private alias TimePeriod = TCal::JSONAPI::DefinitePeriod

  private def condense_periods(periods)
    time_adjust(periods).reduce([] of TimePeriod) do |periods, period|
      if !periods.empty? && period.start == periods[-1].end
        periods << TimePeriod.new(periods.pop.start, period.end)
      else
        periods << period
      end
    end
  end

  private def compat_periods(periods)
    time_adjust(periods).flat_map do |period|
      split_days(period)
    end.map do |period|
      if all_day?(period)
        DatePeriod.new(period.start.date, period.end.date)
      else
        period
      end
    end.reduce([] of DatePeriod | TimePeriod) do |periods, period|
      if !periods.empty? && period.start == periods[-1].end
        last_period = periods.pop

        if period.is_a?(DatePeriod) && last_period.is_a?(DatePeriod)
          periods << DatePeriod.new(last_period.start, period.end)
        elsif period.is_a?(TimePeriod) && last_period.is_a?(TimePeriod)
          periods << TimePeriod.new(last_period.start, period.end)
        else
          raise "unreachable"
        end
      else
        periods << period
      end
    end
  end

  private def time_adjust(periods)
    periods.map do |period|
      TimePeriod.new(adjust_start(period.start), adjust_end(period.end))
    end
  end

  private def adjust_start(time)
    case time.hour
    when .< 9 then time.at_beginning_of_day
    else           time
    end
  end

  private def adjust_end(time)
    case time.hour
    when .>= 22 then time.shift(days: 1).at_beginning_of_day
    when .< 9   then time.at_beginning_of_day
    else             time
    end
  end

  private def all_day?(period)
    period.start != period.end &&
      period.start == period.start.at_beginning_of_day &&
      period.end == period.end.at_beginning_of_day
  end

  private def split_days(period)
    start_next_day = period.start.shift(days: 1).at_beginning_of_day

    if period.start.day != period.end.day && period.end != start_next_day
      [TimePeriod.new(period.start, start_next_day)] +
        split_days(TimePeriod.new(start_next_day, period.end))
    else
      [period]
    end
  end

  private def to_unix(time)
    case time
    when Date then Time.utc(time[0], time[1], time[2], 0, 0, 0).to_unix
    when Time then time.to_unix
    end
  end

  private def format_prop(name, value)
    case value
    when Date then "#{name};VALUE=DATE:#{format_time(value)}"
    when Time then "#{name}:#{format_time(value)}"
    end
  end

  private def format_time(time)
    case time
    when Date
      time[0].to_s + time[1].to_s.rjust(2, '0') + time[2].to_s.rjust(2, '0')
    when Time
      time.to_utc.to_s("%Y%m%dT%H%M%SZ")
    end
  end
end
