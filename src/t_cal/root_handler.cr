class TCal::RootHandler
  include HTTP::Handler

  private README_URL =
    "https://github.com/digitalcora/t-cal/blob/master/README.md"

  def call(context)
    if context.request.path == "/"
      context.response.status = HTTP::Status::TEMPORARY_REDIRECT
      context.response.headers["location"] = README_URL
    else
      call_next(context)
    end
  end
end
