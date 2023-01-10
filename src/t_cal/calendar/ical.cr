require "../calendar"

# Generates an iCal calendar from a collection of MBTA Alerts.
# See [RFC5545](https://tools.ietf.org/html/rfc5545) for the iCal spec.
#
# To minimize duplication and take advantage of the special presentation most
# calendars give to "all-day" events, alert periods that start in the early
# morning or end late at night are adjusted to the nearest day boundary, and
# contiguous periods (after adjustment) are combined.
#
# Events can be generated in two modes: a regular mode and a "compat" mode.
#
# * In regular mode, each alert is output as a single event, with recurrences
#   specified using `RDATE;VALUE=PERIOD`.
#
# * In compat mode, each "chunk" of an alert's periods is output as a separate
#   event, where chunks must either start and end on the same day, or start and
#   end on day boundaries (in which case `VALUE=DATE` is used). This mode is
#   intended for calendar apps that don't support `VALUE=PERIOD`, and/or have
#   an obtrusive presentation of day-spanning events with arbitrary start and
#   end times.
class TCal::Calendar::ICal < TCal::Calendar
  # Increment to "update" all events, e.g. when output logic is changed
  private VERSION = 0

  # Creates a calendar instance.
  # `compat_mode` controls whether "compatible" event output (see class docs)
  # is used.
  def initialize(alerts_with_routes, @compat_mode : Bool)
    super(alerts_with_routes)
  end

  # Writes the iCal data to the specified `IO`.
  def to_s(io : IO) : Nil
    io.puts "BEGIN:VCALENDAR"
    io.puts "VERSION:2.0"
    io.puts "PRODID:-//TCal//NONSGML MBTA Disruptions Calendar//EN"
    io.puts "X-WR-CALNAME:MBTA Disruptions"
    @compat_mode ? output_compat_events(io) : output_events(io)
    io.puts "END:VCALENDAR"
  end

  private def output_events(io)
    @alerts_with_route_colors.each do |alert, route|
      io.puts "BEGIN:VEVENT"
      io.puts "UID:tcal-alert-#{alert.id}"
      output_common_fields(io, alert, route)

      periods = merge_periods(alert.definite_active_periods)
      io.puts "DTSTART:#{periods.first.start.to_ical}"
      io.puts "DTEND:#{periods.first.end.to_ical}"

      if periods.size > 1
        recurrences = periods.skip(1).join(",", &.to_ical)
        io.puts "RDATE;VALUE=PERIOD:#{recurrences}"
      end

      io.puts "END:VEVENT"
    end
  end

  private def output_compat_events(io)
    @alerts_with_route_colors.each do |alert, route_colors|
      merge_periods_separate(alert.definite_active_periods).each do |period|
        io.puts "BEGIN:VEVENT"
        io.puts "UID:tcal-compat-#{alert.id}-#{period.start.to_unix}"
        output_common_fields(io, alert, route_colors)
        io.puts period.start.to_ical("DTSTART")
        io.puts period.end.to_ical("DTEND") if period.start != period.end
        io.puts "END:VEVENT"
      end
    end
  end

  private def output_common_fields(io, alert, route_colors)
    timestamp = alert.updated_at.shift(seconds: VERSION)

    io.puts "SEQUENCE:#{timestamp.to_unix}"
    io.puts "DTSTAMP:#{timestamp.to_ical}"
    io.puts "SUMMARY:#{alert.service_effect}"
    io.puts "DESCRIPTION:#{alert.header}"
    io.puts "URL:#{alert.url}" if !alert.url.nil?
    io.puts "COLOR:#{route_colors.primary.to_ical}" if !route_colors.nil?
  end

  private def merge_periods(alert_periods)
    alert_periods
      .map(&.snap_to_midnight)
      .try { |periods| TimePeriod.merge(periods) }
  end

  private def merge_periods_separate(alert_periods)
    alert_periods
      .map(&.snap_to_midnight)
      .flat_map(&.split_at_midnight)
      .map { |period| period.all_day? ? period.to_date_period : period }
      .try { |periods| Period.merge(periods) }
  end
end
