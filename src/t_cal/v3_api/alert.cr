require "json"
require "../period/time_period"

module TCal::V3API::Alert
  V3API.def_endpoint("/alerts", Resource)

  # An Alert resource.
  struct Resource
    include JSON::Serializable

    getter id : String
    getter attributes : Attributes
    forward_missing_to @attributes
  end

  # The attributes of an Alert resource.
  #
  # The `active_period` and `informed_entity` attributes are remapped to align
  # with the convention that collections have plural names.
  struct Attributes
    include JSON::Serializable

    enum DurationCertainty
      Unknown
      Known
      Estimated
    end

    @[JSON::Field(key: "active_period")]
    getter active_periods : Array(ActivePeriod)
    @description : String?
    getter duration_certainty : DurationCertainty
    getter header : String
    getter image : String?
    getter image_alternative_text : String?
    @[JSON::Field(key: "informed_entity")]
    getter informed_entities : Array(InformedEntity)
    getter service_effect : String
    getter updated_at : Time
    getter url : String?

    # Returns the `active_periods` that are valid and have defined end times.
    def definite_active_periods : Array(TimePeriod)
      active_periods
        .select { |period| !period.end.nil? }
        .select { |period| period.start < period.end.not_nil! }
        .map { |period| TimePeriod.new(period.start, period.end.not_nil!) }
    end

    def description : String?
      # Normalize DOS-style line breaks found in descriptions
      @description.try(&.gsub("\r\n", "\n"))
    end
  end

  # An item in `Attributes#active_periods`.
  struct ActivePeriod
    include JSON::Serializable

    @start : Time
    @end : Time?

    # Times from the API only have a UTC offset as per ISO8601, but since we
    # know the actual time zone the MBTA operates in, we can use that and have
    # our times behave correctly when shifted across DST boundaries.

    def start
      @start.in(TCal::TZ)
    end

    def end
      @end.try(&.in(TCal::TZ))
    end
  end

  # An item in `Attributes#informed_entities`.
  struct InformedEntity
    include JSON::Serializable

    getter route : String?
  end
end
