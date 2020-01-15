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
      periods = alert.definite_active_periods

      io.puts "BEGIN:VEVENT"
      io.puts "UID:tcal-v#{VERSION}-#{alert.id}"
      io.puts "SEQUENCE:#{alert.updated_at.to_unix}"
      io.puts "SUMMARY:#{alert.service_effect}"
      io.puts "DESCRIPTION:#{alert.header}"
      io.puts "URL:#{alert.url}" if !alert.url.nil?
      io.puts "DTSTAMP:#{format_time(alert.updated_at)}"
      io.puts "DTSTART:#{format_time(periods.first.start)}"
      io.puts "DTEND:#{format_time(periods.first.end)}"

      if periods.size > 1
        formatted_periods = periods.skip(1).map do |period|
          "#{format_time(period.start)}/#{format_time(period.end)}"
        end
        io.puts "RDATE;VALUE=PERIOD:#{formatted_periods.join(",")}"
      end

      io.puts "END:VEVENT"
    end

    io.puts "END:VCALENDAR"
  end

  private def format_time(time)
    time.to_utc.to_s("%Y%m%dT%H%M%SZ")
  end
end
