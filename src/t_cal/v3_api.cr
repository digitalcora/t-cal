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

  private Log = ::Log.for(self)

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
    #
    # Maintains an in-memory cache using `Last-Modified`/`If-Modified-Since`
    # headers. Always checks with the server to ensure the cached data is not
    # stale, but since 304 responses don't count against the rate limit, this
    # makes it practical to use anonymous access (which has a very low limit).
    #
    # Throws `V3API::RequestError` on an HTTP status other than 200 or 304.
    def self.all!(filters = {} of String => String) : Array({{resource}})
      params = filters.transform_keys { |key| "filter[#{key}]" }
      Response.from_json(V3API.fetch!({{path}}, params)).data
    end
  end

  class RequestError < Exception
  end

  private record CachedResponse, body : String, last_modified : String
  @@response_cache = {} of String => CachedResponse

  protected def self.fetch!(
    path : String, params = {} of String => String
  ) : String
    query = URI::Params.encode(params)
    url = URI.new(**BASE_URI, path: path, query: query).to_s
    headers, cached_response = HEADERS, @@response_cache[url]?

    if cached_response
      headers = headers.clone
      headers["If-Modified-Since"] = cached_response.last_modified
    end

    response = HTTP::Client.get(url, headers)

    case
    when response.status == HTTP::Status::OK
      last_modified = response.headers["Last-Modified"]
      Log.debug &.emit("HTTP 200", last_modified: last_modified)
      @@response_cache[url] = CachedResponse.new(response.body, last_modified)
      response.body
    when response.status == HTTP::Status::NOT_MODIFIED && cached_response
      Log.debug &.emit("HTTP 304")
      cached_response.body
    else
      raise RequestError.new("HTTP #{response.status.value}: #{response.body}")
    end
  end
end
