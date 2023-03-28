require "./color"
require "./period/date_period"
require "./v3_api"
require "./v3_api/alert"

# Classes that convert a collection of MBTA Alerts into calendar events, based
# on the `active_period` of the alerts.
#
# Calendars have the common behavior of simplifying and combining alert time
# periods into "all-day" date periods. This allows for a cleaner presentation
# in most cases.
abstract class TCal::Calendar
  protected record RouteColors, primary : Color, text : Color

  @alerts : Array({V3API::Alert::Resource, Array(DatePeriod), RouteColors?})

  def initialize(alerts_with_routes : V3API::AlertsWithRoutes)
    @alerts = alerts_with_routes.map do |alert, routes|
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
