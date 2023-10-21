require "json"

module TCal::V3API::Line
  V3API.def_endpoint(
    "/lines",
    Resource,
    {"include" => "routes", "fields[route]" => ""}
  )

  # A Line resource.
  struct Resource
    include JSON::Serializable

    getter id : String
    @relationships : Relationships

    # The IDs of the Routes that make up the Line.
    def route_ids : Array(String)
      @relationships.routes.data.map(&.id)
    end
  end

  # :nodoc:
  struct Relationships
    include JSON::Serializable

    getter routes : Routes
  end

  # :nodoc:
  struct Routes
    include JSON::Serializable

    getter data : Array(Route)
  end

  # :nodoc:
  struct Route
    include JSON::Serializable

    getter id : String
  end
end
