require "json"
require "../color"

module TCal::V3API::Route
  V3API.def_endpoint("/routes", Resource)

  # A Route resource.
  struct Resource
    include JSON::Serializable

    getter id : String
    getter attributes : Attributes
    forward_missing_to @attributes
  end

  # The attributes of a Route resource.
  struct Attributes
    include JSON::Serializable

    getter color : Color
    getter text_color : Color
  end
end
