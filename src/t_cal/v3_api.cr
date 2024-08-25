require "cache"
require "http/client"
require "raven"
require "json"
require "uri"

# Modules for fetching JSON:API data from the MBTA's V3 API.
# See also the [API reference](https://api-v3.mbta.com/docs/swagger/index.html).
module TCal::V3API
  # Defines a `self.all!` method that calls a V3 API "index" endpoint.
  #
  # `path` is the absolute path of the endpoint. `resource` is the class for
  # deserializing resource instances. `params` are extra parameters that should
  # be added to all requests.
  macro def_endpoint(path, resource, params = {} of String => String)
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
    # If the server returns a 5xx error and there is a cached response, returns
    # it and logs a warning.
    #
    # Throws `V3API::RequestError` when an unexpected HTTP status is received,
    # including a 5xx status when there is no cached response.
    def self.all!(filters = {} of String => Array(String)) : Array({{resource}})
      params = filters
        .transform_keys { |key| "filter[#{key}]" }
        .transform_values { |value| value.join(",") }
        .merge({{params}})

      Response.from_json(V3API.fetch!({{path}}, params)).data
    end
  end

  class RequestError < Exception
  end

  private class ServerError < Exception
  end

  private record CachedResponse, body : String, last_modified : String

  private Log = ::Log.for(self)

  private BASE_URI = {scheme: "https", host: "api-v3.mbta.com"}
  private HEADERS  = HTTP::Headers{"MBTA-Version" => "2021-01-09"}

  private CACHE =
    Cache::MemoryStore(String, CachedResponse).new(expires_in: 1.day)

  protected def self.fetch!(
    path : String, params = {} of String => String
  ) : String
    query = URI::Params.encode(params)
    url = URI.new(**BASE_URI, path: path, query: query).to_s
    headers, cached_response = HEADERS, CACHE.read(url)

    if cached_response
      headers = headers.clone
      headers["If-Modified-Since"] = cached_response.last_modified
    end

    response = HTTP::Client.get(url, headers)

    case
    when response.status == HTTP::Status::OK
      last_modified = response.headers["Last-Modified"]
      Log.debug &.emit("HTTP 200", last_modified: last_modified)
      CACHE.write(url, CachedResponse.new(response.body, last_modified))
      response.body
    when response.status == HTTP::Status::NOT_MODIFIED && cached_response
      Log.debug &.emit("HTTP 304")
      cached_response.body
    when response.status.server_error? && cached_response
      Log.warn &.emit("HTTP 5xx", response_body: response.body)
      Raven.capture(ServerError.new(response.body), level: :warning)
      cached_response.body
    else
      raise RequestError.new("HTTP #{response.status.value}: #{response.body}")
    end
  end
end
