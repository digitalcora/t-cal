require "./color"
require "./v3_api"
require "./v3_api/alert"

# Classes that convert a collection of MBTA Alerts into calendar events, based
# on the `active_period` of the alerts.
abstract class TCal::Calendar
  protected record RouteColors, primary : Color, text : Color

  @alerts_with_route_colors : Array({V3API::Alert::Resource, RouteColors?})

  def initialize(alerts_with_routes : V3API::AlertsWithRoutes)
    @alerts_with_route_colors = alerts_with_routes.map do |alert, routes|
      route_colors = routes
        .map { |route| RouteColors.new(route.color, route.text_color) }
        .uniq!

      {alert, (route_colors[0] if route_colors.size == 1)}
    end
  end
end
