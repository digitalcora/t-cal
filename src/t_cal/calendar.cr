require "./period"
require "./v3_api"

class TCal::Calendar
  @alerts : Array(V3API::Alert)

  private VERSION = 1 # Increment to invalidate existing UIDs

  def initialize(alerts, @compat_mode : Bool)
    @alerts = alerts.select(&.definite_active_periods.any?)
  end

  def to_s(io)
    io.puts "BEGIN:VCALENDAR"
    io.puts "VERSION:2.0"
    io.puts "PRODID:-//TCal//NONSGML MBTA Disruptions Calendar//EN"
    io.puts "X-WR-CALNAME:MBTA Disruptions"
    @compat_mode ? output_compat_events(io) : output_events(io)
    io.puts "END:VCALENDAR"
  end

  private def output_events(io)
    @alerts.each do |alert|
      io.puts "BEGIN:VEVENT"
      io.puts "UID:tcal-v#{VERSION}-#{alert.id}"
      output_common_fields(io, alert)

      periods = condense_periods(alert.definite_active_periods)
      io.puts "DTSTART:#{periods.first.start.to_ical}"
      io.puts "DTEND:#{periods.first.end.to_ical}"

      if periods.size > 1
        recurrences = periods.skip(1).map(&.to_ical).join(",")
        io.puts "RDATE;VALUE=PERIOD:#{recurrences}"
      end

      io.puts "END:VEVENT"
    end
  end

  private def output_compat_events(io)
    @alerts.each do |alert|
      compat_condense_periods(alert.definite_active_periods).each do |period|
        io.puts "BEGIN:VEVENT"
        io.puts "UID:tcal-v#{VERSION}-#{alert.id}-#{period.start.to_unix}"
        output_common_fields(io, alert)
        io.puts period.start.to_ical("DTSTART")
        io.puts period.end.to_ical("DTEND") if period.start != period.end
        io.puts "END:VEVENT"
      end
    end
  end

  private def output_common_fields(io, alert)
    io.puts "SEQUENCE:#{alert.updated_at.to_unix}"
    io.puts "SUMMARY:#{alert.service_effect}"
    io.puts "DESCRIPTION:#{alert.header}"
    io.puts "URL:#{alert.url}" if !alert.url.nil?
    io.puts "DTSTAMP:#{alert.updated_at.to_ical}"
  end

  private def condense_periods(periods)
    periods
      .map(&.snap_to_midnight)
      .reduce([] of TimePeriod) { |acc, period| period.merge_into!(acc) }
  end

  private alias SomePeriod = DatePeriod | TimePeriod

  private def compat_condense_periods(periods)
    periods
      .map(&.snap_to_midnight)
      .flat_map(&.split_at_midnight)
      .map { |period| period.all_day? ? period.to_date_period : period }
      .reduce([] of SomePeriod) { |acc, period| period.merge_into!(acc) }
  end
end
