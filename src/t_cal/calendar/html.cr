require "html"
require "json"
require "../calendar"
require "../date"
require "../period/date_period"
require "../v3_api/alert"

# Converts a collection of MBTA Alerts into a form convenient for rendering a
# month-view HTML calendar using CSS grids.
class TCal::Calendar::HTML < TCal::Calendar
  getter months : Array(Month)

  # Represents a view of all weeks in a month. `start` is the first day of the
  # month. The view is assumed to be a rectangular grid, so it may also include
  # days that are not part of the month.
  record Month, events : Array(MonthEvent), start : Date, weeks : Array(Week) do
    # Produces a title for the month view, e.g. "December 2022".
    def title : String
      start.to_time.to_s("%B %Y")
    end
  end

  # Represents a week within a `Month`. Events (other than "all-month" events)
  # are split on week boundaries to allow using CSS grids for visual layout.
  record Week,
    days : {Date, Date, Date, Date, Date, Date, Date},
    events : Array(WeekEvent)

  # Base struct for calendar events.
  abstract struct Event
    getter alert : V3API::Alert::Resource
    getter colors : Calendar::RouteColors?

    def initialize(@alert, @colors)
    end

    def title : String
      ::HTML.escape(alert.service_effect)
    end

    def description : String
      ::HTML.escape(alert.header)
    end

    def details : String?
      alert.description.try { |desc| ::HTML.escape(desc).gsub("\n", "<br>") }
    end

    def url : String?
      alert.url.try { |url| ::HTML.escape(url) }
    end
  end

  # Represents an "all-month" event within a `Month`.
  struct MonthEvent < Event
    # Provides a key for sorting "all-month" events. See `WeekEvent#sort_key`.
    def sort_key
      {colors.nil? ? 0 : 1, title}
    end
  end

  # Represents an event within a `Week`.
  #
  # If `starts_this_week` or `ends_this_week` are false, the event should be
  # shown as continuing from the previous week or into the next week. Note that
  # `period` only includes days within "this" week.
  struct WeekEvent < Event
    getter period : DatePeriod
    getter starts_this_week : Bool
    getter ends_this_week : Bool

    def initialize(@alert, @colors, @period, @starts_this_week, @ends_this_week)
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
    # * then when they have no associated route colors
    # * then when their title is alphabetically earlier
    def sort_key
      {
        (!starts_this_week && !ends_this_week) ? 0 : 1,
        !starts_this_week ? 0 : 1,
        start_column,
        colors.nil? ? 0 : 1,
        title,
      }
    end
  end

  # Creates a calendar instance.
  # `today` is used to ensure the calendar includes the current date.
  def initialize(today : Date)
    super()

    # NOTES FOR COMPLETION
    #
    # 1. Get min and max months directly from @alerts
    # 2. Initialize "empty" months as Date => Month
    # 3. Iterate @alerts and insert all-month events
    # 4. Iterate @alerts and insert week events depending on all-month events
    #
    # Requires refactoring of Month/Week/etc. data structures:
    #   {Date => Month(events: [MonthEvent], weeks: {Date => Week(...)})}
    #
    # Don't store original dates/periods where possible? Mostly not needed to
    # render the calendar...

    month_events_by_month =
      Hash(Date, Set({V3API::Alert::Resource, RouteColors?}))
        .new { |h, k| h[k] = Set({V3API::Alert::Resource, RouteColors?}).new }

    @alerts.each do |alert, date_periods, route_colors|
      date_periods.each do |full_period|
        full_period.split_by_month.select(&.all_month?).each do |month_period|
          month_events_by_month[month_period.start] << {alert, route_colors}
        end
      end
    end

    week_events_by_month_week =
      Hash({Date, Date}, Set({V3API::Alert::Resource, DatePeriod, RouteColors?}))
        .new { |h, k| h[k] = Set({V3API::Alert::Resource, DatePeriod, RouteColors?}).new }

    @alerts.each do |alert, date_periods, route_colors|
      date_periods.each do |full_period|
        full_period.split_at_sunday.each do |week_period|
          {week_period.start, week_period.end.shift(days: -1)}.each do |day|
            unless month_events_by_month[day.at_beginning_of_month].includes?({alert, route_colors})
              week_events_by_month_week[{day.at_beginning_of_month, day.at_beginning_of_sunday_week}] <<
                {alert, week_period, route_colors}
            end
          end
        end
      end
    end

    min = (
      [today] |
      month_events_by_month.keys |
      week_events_by_month_week.values.flat_map(&.to_a).map { |event| event[1].start }
    ).compact.min

    max = (
      [today.shift(days: 1)] |
      month_events_by_month.keys.map(&.shift(months: 1)) |
      week_events_by_month_week.values.flat_map(&.to_a).map { |event| event[1].end }
    ).compact.max

    @months = DatePeriod.new(min, max).each_month.map do |month_start|
      month = DatePeriod.new(month_start, month_start.shift(months: 1))
      month_events = month_events_by_month[month_start].map do |event|
        MonthEvent.new(event[0], event[1])
      end.sort_by(&.sort_key)

      weeks = month.each_sunday_week.map do |week_start|
        week_events = week_events_by_month_week[{month_start, week_start}].map do |event|
          WeekEvent.new(event[0], event[2], event[1], false, false)
        end.sort_by(&.sort_key)

        Week.new(
          events: week_events,
          days: {0, 1, 2, 3, 4, 5, 6}.map { |num| week_start.shift(days: num) }
        )
      end.to_a

      Month.new(start: month_start, events: month_events, weeks: weeks)
    end.to_a
  end
end
