require "json"
require "../calendar"
require "../date"
require "../period/date_period"
require "../v3_api/alert"
require "../v3_api/route"

# Converts a collection of MBTA Alerts into a form convenient for rendering a
# month-view HTML calendar using CSS grids.
#
# All events are treated as "all-day"; if an alert's active period covers any
# part of a day, it is considered to occupy that entire day.
class TCal::Calendar::HTML < TCal::Calendar
  getter months : Array(Month)

  # Represents a view of all weeks in a month. `start` is the first day of the
  # month. The view is assumed to be a rectangular grid, so it may also include
  # days that are not part of the month.
  record Month, start : Date, weeks : Array(Week) do
    # Produces a title for the month view, e.g. "December 2022".
    def title : String
      start.to_time.to_s("%B %Y")
    end
  end

  # Represents a week within a `Month`. Events are split on week boundaries to
  # enable the use of CSS grids for visual layout, so they are specified here.
  record Week,
    days : {Date, Date, Date, Date, Date, Date, Date},
    events : Array(Event)

  # Represents an event within a `Week`.
  #
  # If `starts_this_week` or `ends_this_week` are false, the event should be
  # shown as continuing from the previous week or into the next week. `period`
  # only includes days within "this" week.
  record Event,
    alert : V3API::Alert::Resource,
    route : V3API::Route::Resource?,
    period : DatePeriod,
    starts_this_week : Bool,
    ends_this_week : Bool do
    def title : String
      alert.service_effect
    end

    def description : String
      alert.header
    end

    def url : String?
      alert.url
    end

    # The 1-based grid column the event starts on.
    def start_column : Int32
      period.start.day_of_week.sunday_value
    end

    # The 1-based grid column the event ends on.
    #
    # This is exclusive (the event occupies the columns from `start_column` up
    # to, but not including, this one). Because of this, it can have the value
    # `8` despite the grid only being expected to contain 7 columns. This is in
    # line with the behavior of `grid-column-end` in CSS.
    def end_column : Int32
      value = period.end.day_of_week.sunday_value
      value == 1 ? 8 : value
    end

    # Provides a key for sorting events.
    #
    # Events are sorted earlier:
    # * when they continue from the previous week and into the next week
    # * then when they continue from the previous week
    # * then when they start in an earlier column
    # * then when they have no associated route
    # * then when the ID of their associated route is alphabetically earlier
    # * then when their title is alphabetically earlier
    def sort_key
      {
        (!starts_this_week && !ends_this_week) ? 0 : 1,
        !starts_this_week ? 0 : 1,
        start_column,
        route.nil? ? 0 : 1,
        route.try(&.id) || "",
        title,
      }
    end
  end

  # Creates a calendar instance.
  # `today` is used to ensure the calendar includes the current date.
  def initialize(@alerts_with_routes, today : Date)
    events = @alerts_with_routes.flat_map do |alert, route|
      alert
        .definite_active_periods
        .map(&.snap_to_midnight)
        .map(&.all_day)
        .map(&.to_date_period)
        .try { |periods| DatePeriod.merge(periods) }
        .map(&.split_at_sunday)
        .flat_map do |periods|
          periods.map do |period|
            Event.new(
              alert: alert,
              route: route,
              period: period,
              starts_this_week: period == periods[0],
              ends_this_week: period == periods[-1],
            )
          end
        end
    end

    min = {today, events.min_of(&.period.start)}.min
    max = {today, events.max_of(&.period.end)}.max
    events_by_week = events.group_by(&.period.start.at_beginning_of_sunday_week)

    @months = DatePeriod.new(min, max).each_month.map do |month_start|
      month = DatePeriod.new(month_start, month_start.at_end_of_month)

      weeks = month.each_sunday_week.map do |week_start|
        events = (events_by_week[week_start]? || [] of Event)

        Week.new(
          events: events.sort_by(&.sort_key),
          days: {0, 1, 2, 3, 4, 5, 6}.map { |num| week_start.shift(days: num) }
        )
      end.to_a

      Month.new(start: month_start, weeks: weeks)
    end.to_a
  end
end
