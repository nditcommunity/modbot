Sentry.init do |config|
  config.enabled_environments = ["production"]
  config.dsn = "https://6b394d1774f5430d8a1653250bcc1c63@o1150717.ingest.sentry.io/6224141"
  config.send_default_pii = false
  # Reports and response URLs must not appear in request or HTTP breadcrumbs.
  config.breadcrumbs_logger = []
  config.before_breadcrumb = ->(_breadcrumb, _hint) {}
  scrub_request = lambda do |event, _hint|
    if event.request
      event.request.data = nil
      event.request.query_string = nil
      event.request.cookies = nil
      event.request.headers = {}
      event.request.env = {}
    end
    event.breadcrumbs = nil
    event.extra = {}
    event.user = {}
    event
  end
  config.before_send = scrub_request
  config.before_send_transaction = scrub_request

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end
