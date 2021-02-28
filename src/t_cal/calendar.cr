require "./period"
require "./v3_api"

# Generates an iCal calendar from a collection of MBTA Alerts.
# See [RFC5545](https://tools.ietf.org/html/rfc5545) for the iCal spec.
#
# Events are generated based on the `active_period` of alerts. For a cleaner
# calendar view, early-morning and late-night times are "snapped" to the nearest
# day boundary, and contiguous time periods (after snapping) are combined. This
# results in most "start to end of service" alerts appearing as all-day events.
#
# Events can be generated in two modes: a regular mode and a "compat" mode. In
# the former, each alert is output as a single event, with recurrences specified
# using `RDATE;VALUE=PERIOD`. In the latter, each "chunk" of an alert is output
# as a separate event, where chunks must either A) start and end on the same
# day, or B) start and end on day boundaries, in which case the endpoints are
# specified using `VALUE=DATE`.
#
# "Compat" mode is intended for calendar apps that don't support `VALUE=PERIOD`,
# and/or have an obtrusive presentation of day-spanning events with arbitrary
# start and end times. Since these two categories tend to overlap, the changes
# needed to support them are combined in one mode.
class TCal::Calendar
  @alerts : Array(V3API::Alert)

  # Increment to "update" all events, e.g. when output logic is changed
  private VERSION = 0

  # Creates a calendar instance.
  # `compat_mode` controls whether "compatible" event output will be used.
  def initialize(alerts : Array(V3API::Alert), @compat_mode : Bool)
    @alerts = alerts.reject(&.definite_active_periods.empty?)
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
    @alerts.each do |alert|
      io.puts "BEGIN:VEVENT"
      io.puts "UID:tcal-alert-#{alert.id}"
      output_common_fields(io, alert)

      periods = condense_periods(alert.definite_active_periods)
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
    @alerts.each do |alert|
      compat_condense_periods(alert.definite_active_periods).each do |period|
        io.puts "BEGIN:VEVENT"
        io.puts "UID:tcal-compat-#{alert.id}-#{period.start.to_unix}"
        output_common_fields(io, alert)
        io.puts period.start.to_ical("DTSTART")
        io.puts period.end.to_ical("DTEND") if period.start != period.end
        io.puts "END:VEVENT"
      end
    end
  end

  private def output_common_fields(io, alert)
    timestamp = alert.updated_at.shift(seconds: VERSION)

    io.puts "SEQUENCE:#{timestamp.to_unix}"
    io.puts "DTSTAMP:#{timestamp.to_ical}"
    io.puts "SUMMARY:#{alert.service_effect}"
    io.puts "DESCRIPTION:#{alert.header}"
    io.puts "URL:#{alert.url}" if !alert.url.nil?
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
