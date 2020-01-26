require "json"
require "./period"

module TCal::V3API
  struct AlertsResponse
    include JSON::Serializable

    getter data : Array(Alert)
  end

  struct Alert
    include JSON::Serializable

    getter id : String
    getter attributes : AlertAttributes
    forward_missing_to @attributes
  end

  struct AlertAttributes
    include JSON::Serializable

    @[JSON::Field(key: "active_period")]
    getter active_periods : Array(ActivePeriod)
    getter effect : String
    getter header : String
    getter service_effect : String
    getter updated_at : Time
    getter url : String?

    def definite_active_periods
      active_periods
        .select { |period| !period.end.nil? }
        .map { |period| TimePeriod.new(period.start, period.end.not_nil!) }
    end
  end

  struct ActivePeriod
    include JSON::Serializable

    getter start : Time
    getter end : Time?
  end
end
