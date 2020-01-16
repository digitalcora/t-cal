require "./json_api"

class TCal::Calendar
  @alerts : Array(TCal::JSONAPI::Alert)

  private VERSION = 1 # Increment to invalidate existing UIDs

  def initialize(alerts)
    @alerts = alerts.select do |alert|
      alert.effect == "SHUTTLE" && alert.definite_active_periods.any?
    end
  end

  def to_s(io)
    io.puts "BEGIN:VCALENDAR"
    io.puts "VERSION:2.0"
    io.puts "PRODID:-//TCal//NONSGML MBTA Shuttles Calendar//EN"
    io.puts "X-WR-CALNAME:MBTA Shuttles"

    @alerts.each do |alert|
      io.puts "BEGIN:VEVENT"
      io.puts "UID:tcal-v#{VERSION}-#{alert.id}"
      io.puts "SEQUENCE:#{alert.updated_at.to_unix}"
      io.puts "SUMMARY:#{alert.service_effect}"
      io.puts "DESCRIPTION:#{alert.header}"
      io.puts "URL:#{alert.url}" if !alert.url.nil?
      io.puts "DTSTAMP:#{format_time(alert.updated_at)}"

      periods = condense(alert.definite_active_periods)
      io.puts "DTSTART:#{format_time(periods.first.start)}"
      io.puts "DTEND:#{format_time(periods.first.end)}"

      if periods.size > 1
        recurrences = periods.skip(1).map do |period|
          "#{format_time(period.start)}/#{format_time(period.end)}"
        end
        io.puts "RDATE;VALUE=PERIOD:#{recurrences.join(",")}"
      end

      io.puts "END:VEVENT"
    end

    io.puts "END:VCALENDAR"
  end

  private alias TimePeriod = TCal::JSONAPI::DefinitePeriod

  private def condense(periods)
    periods.map do |period|
      TimePeriod.new(adjust_start(period.start), adjust_end(period.end))
    end.reduce([] of TimePeriod) do |periods, period|
      if !periods.empty? && period.start == periods[-1].end
        periods << TimePeriod.new(periods.pop.start, period.end)
      else
        periods << period
      end
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

  private def format_time(time)
    time.to_utc.to_s("%Y%m%dT%H%M%SZ")
  end
end
