require "./color"
require "./period/date_period"
require "./v3_api"
require "./v3_api/alert"
require "./v3_api/line"
require "./v3_api/route"

# Classes that build calendar events from the `active_period` of MBTA Alerts.
#
# Calendars have the common behavior of simplifying and combining alert time
# periods into "all-day" date periods. This allows for a cleaner presentation
# in most cases.
#
# **Note:** Currently alerts are fetched internally as part of initialization,
# as there is no need yet to split out or customize the API interactions.
abstract class TCal::Calendar
  protected record RouteColors, primary : Color, text : Color

  # IDs of Lines to fetch alerts for, minus the `line-` prefix which is common
  # to all Line IDs.
  private LINES = %w(Blue Green Mattapan Orange Red)

  @alerts : Array({V3API::Alert::Resource, Array(DatePeriod), RouteColors?})

  def initialize
    lines = V3API::Line.all!({"id" => LINES.map { |line| "line-#{line}" }})

    alerts = V3API::Alert
      .all!({"route" => lines.flat_map(&.route_ids)})
      .reject(&.transient?)
      .reject(&.definite_active_periods.empty?)

    route_ids = alerts.flat_map(&.informed_entities).compact_map(&.route).uniq!
    routes_by_id = V3API::Route.all!({"id" => route_ids}).index_by(&.id)

    @alerts = alerts
      .map do |alert|
        {
          alert,
          alert
            .informed_entities
            .compact_map { |entity| routes_by_id[entity.route]? }
            .uniq!,
        }
      end
      .map do |alert, routes|
        date_periods = alert
          .definite_active_periods
          .map(&.snap_to_midnight)
          .map(&.all_day)
          .map(&.to_date_period)
          .try { |periods| DatePeriod.merge(periods) }

        route_colors = routes
          .map { |route| RouteColors.new(route.color, route.text_color) }
          .uniq!

        {alert, date_periods, (route_colors[0] if route_colors.size == 1)}
      end
  end
end
