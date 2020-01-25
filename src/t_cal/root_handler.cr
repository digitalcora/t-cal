require "http/server/handler"

# HTTP handler (see `HTTP::Handler`) that redirects to this project's README on
# GitHub if the request is for the root path.
class TCal::RootHandler
  include HTTP::Handler

  private README_URL =
    "https://github.com/digitalcora/t-cal/blob/master/README.md"

  # :nodoc:
  def call(context)
    if context.request.path == "/"
      context.response.status = HTTP::Status::TEMPORARY_REDIRECT
      context.response.headers["location"] = README_URL
    else
      call_next(context)
    end
  end
end
