require "json"
require "./period"

module TCal::V3API
  class AlertsResponse
    include JSON::Serializable

    getter data : Array(Alert)
  end

  class Alert
    include JSON::Serializable

    getter id : String
    getter attributes : AlertAttributes
    forward_missing_to @attributes
  end

  class AlertAttributes
    include JSON::Serializable

    @[JSON::Field(key: "active_period")]
    getter active_periods : Array(ActivePeriod)
    getter effect : String
    getter header : String
    getter service_effect : String
    getter updated_at : Time
    getter url : String?

    @[JSON::Field(ignore: true)]
    @_definite_active_periods : Array(TimePeriod)?

    def definite_active_periods
      @_definite_active_periods ||= active_periods
        .select { |period| !period.end.nil? }
        .map { |period| TimePeriod.new(period.start, period.end.not_nil!) }
    end
  end

  class ActivePeriod
    include JSON::Serializable

    getter start : Time
    getter end : Time?
  end
end
