require "http/server/handler"
require "./rollbar"

class TCal::ErrorHandler
  include HTTP::Handler

  def initialize(@log_io : IO, @rollbar : Rollbar?)
  end

  def call(context)
    begin
      call_next(context)
    rescue ex : Exception
      context.response.respond_with_status(:internal_server_error)
      @rollbar.try(&.error(ex))
    end
  end
end
