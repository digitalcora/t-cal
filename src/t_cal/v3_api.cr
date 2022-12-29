require "http/client"
require "json"
require "uri"

# Modules for fetching JSON:API data from the MBTA's V3 API.
# See also the [API reference](https://api-v3.mbta.com/docs/swagger/index.html).
module TCal::V3API
  alias AlertsWithRoutes = Array({Alert::Resource, Route::Resource?})

  private CALENDAR_ALERT_FILTERS = {
    "route_type" => "0,1",
    "severity"   => "3,4,5,6,7,8,9,10",
  }

  # One-stop shop for fetching the alerts used with `Calendar` builders.
  #
  # Any routes associated with each alert via its `informed_entities` are also
  # fetched. If an alert has exactly one associated route, it is returned along
  # with the alert, otherwise the second tuple element is `nil`.
  def self.calendar_alerts_with_routes : AlertsWithRoutes
    alerts = Alert.all!(CALENDAR_ALERT_FILTERS)
    route_ids = alerts.flat_map(&.informed_entities).compact_map(&.route).uniq!
    routes_by_id = Route.all!({"id" => route_ids.join(",")}).index_by(&.id)

    alerts
      .reject(&.transient?)
      .reject(&.definite_active_periods.empty?)
      .map do |alert|
        alert_routes = alert.informed_entities.compact_map(&.route).uniq!
        {alert, (routes_by_id[alert_routes[0]] if alert_routes.size == 1)}
      end
  end

  private BASE_URI = {scheme: "https", host: "api-v3.mbta.com"}
  private HEADERS  = HTTP::Headers{"MBTA-Version" => "2021-01-09"}

  # Defines a `self.all!` method that calls a V3 API "index" endpoint.
  #
  # `path` is the absolute path of the endpoint. `resource` is the class for
  # deserializing resource instances.
  macro def_endpoint(path, resource)
    private struct Response
      include JSON::Serializable
      getter data : Array({{resource}})
    end

    # Fetches all `{{resource}}` matching the given filters.
    # Raises an exception on a non-200 response from the API.
    def self.all!(filters = {} of String => String) : Array({{resource}})
      params = filters.transform_keys { |key| "filter[#{key}]" }
      V3API.fetch!({{path}}, params) { |json| Response.from_json(json).data }
    end
  end

  protected def self.fetch!(path : String, params = {} of String => String)
    uri = URI.new(**BASE_URI, path: path, query: URI::Params.encode(params))

    HTTP::Client.get(uri, HEADERS) do |response|
      if response.status == HTTP::Status::OK
        yield response.body_io
      else
        raise "Unexpected response: #{response.body_io.gets_to_end}"
      end
    end
  end
end
