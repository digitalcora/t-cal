require "http/client"
require "json"
require "uri"

# Modules for fetching JSON:API data from the MBTA's V3 API.
# See also the [API reference](https://api-v3.mbta.com/docs/swagger/index.html).
module TCal::V3API
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
