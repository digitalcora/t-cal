require "./json_api"

class TCal::Calendar
  @alerts : Array(TCal::JSONAPI::Alert)

  def initialize(alerts)
    @alerts = alerts.select do |alert|
      alert.effect == "SHUTTLE" && alert.definite_active_periods.any?
    end
  end

  def to_s(io)
    io.puts "BEGIN:VCALENDAR"
    io.puts "VERSION:2.0"

    @alerts.each do |alert|
      first_period = alert.definite_active_periods.first
      other_periods = alert.definite_active_periods.skip(1)

      io.puts "BEGIN:VEVENT"
      io.puts "UID:#{alert.id}"
      io.puts "SUMMARY:#{alert.service_effect || "Shuttles"}"
      io.puts "DTSTAMP:#{format_time(alert.created_at)}"
      io.puts "DTSTART:#{format_time(first_period.start)}"
      io.puts "DTEND:#{format_time(first_period.end)}"

      if other_periods.any?
        io << "RDATE;VALUE=PERIOD:"
        io.puts other_periods.map { |period| format_period(period) }.join(",")
      end

      io.puts "END:VEVENT"
    end

    io.puts "END:VCALENDAR"
  end

  private def format_period(period)
    "#{format_time(period.start)}/#{format_time(period.end)}"
  end

  private def format_time(time)
    time.to_utc.to_s("%Y%m%dT%H%M%SZ")
  end
end
