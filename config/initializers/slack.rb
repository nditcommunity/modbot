if Rails.env.production? && ENV["SLACK_SIGNING_SECRET"].blank?
  raise "SLACK_SIGNING_SECRET must be configured"
end

Slack.configure do |config|
  config.token = ENV["SLACK_API_TOKEN"]
end

Slack::Events.configure do |config|
  config.signing_secret = ENV["SLACK_SIGNING_SECRET"]
end
