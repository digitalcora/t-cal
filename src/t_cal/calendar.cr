require "./v3_api"

# Classes that convert a collection of MBTA Alerts into calendar events, based
# on the `active_period` of the alerts.
abstract class TCal::Calendar
  def initialize(@alerts_with_routes : V3API::AlertsWithRoutes)
  end
end
