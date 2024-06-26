require "../calendar"
require "../v3_api/alert"

# Generates an iCal calendar from a collection of MBTA Alerts.
# See [RFC5545](https://datatracker.ietf.org/doc/html/rfc5545) for the iCal
# spec, and [RFC7986](https://datatracker.ietf.org/doc/html/rfc7986) for
# additional properties.
#
# Alerts can have an arbitrary set of periods. The equivalent iCal concept is
# `RDATE;VALUE=PERIOD`, but unfortunately most calendar apps don't support this
# part of the standard. Therefore each period is output as a separate event.
class TCal::Calendar::ICal < TCal::Calendar
  # Characters that must be escaped in TEXT property values.
  private ESCAPE_CHARS = {
    '\\' => "\\\\",
    ';'  => "\\;",
    ','  => "\\,",
    '\n' => "\\n",
  }

  # Increment to "update" all events, e.g. when output logic is changed
  private VERSION = 0

  # Creates a calendar instance.
  def initialize
    super
  end

  # Writes the iCal data to the specified `IO`.
  def to_s(io : IO) : Nil
    io.puts "BEGIN:VCALENDAR"
    io.puts "VERSION:2.0"
    io.puts "PRODID:-//TCal//NONSGML MBTA Disruptions Calendar//EN"
    io.puts "X-WR-CALNAME:MBTA Disruptions"

    @alerts.each do |alert, date_periods, route_colors|
      timestamp = alert.updated_at.shift(seconds: VERSION)

      date_periods.each do |period|
        io.puts "BEGIN:VEVENT"
        io.puts "UID:tcal-#{alert.id}-#{period.start.to_ical}"
        io.puts "SEQUENCE:#{timestamp.to_unix}"
        io.puts "DTSTAMP:#{timestamp.to_ical}"
        io.puts "DTSTART;VALUE=DATE:#{period.start.to_ical}"
        io.puts "DTEND;VALUE=DATE:#{period.end.to_ical}"
        io.puts "SUMMARY:#{escape(alert.service_effect)}"
        io.puts "DESCRIPTION:#{escape(description(alert))}"
        io.puts "URL:#{alert.url}" if !alert.url.nil?
        if !alert.image.nil?
          io.puts "IMAGE;VALUE=URI;DISPLAY=FULLSIZE:#{alert.image}"
        end
        io.puts "COLOR:#{route_colors.primary.to_ical}" if !route_colors.nil?
        io.puts "END:VEVENT"
      end
    end

    io.puts "END:VCALENDAR"
  end

  private def description(alert : V3API::Alert::Resource) : String
    [alert.header, alert.description].compact.join("\n\n")
  end

  private def escape(value : String) : String
    value.gsub(ESCAPE_CHARS)
  end
end
