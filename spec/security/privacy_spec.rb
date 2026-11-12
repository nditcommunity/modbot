require "rails_helper"

RSpec.describe "Slack data privacy" do
  let(:report) { "private-garden-report" }
  let(:response_url) { "https://example.test/private-response-capability" }

  it "filters command text and response URLs from Rails parameters" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    result = filter.filter("text" => report, "response_url" => response_url, "nested" => {"text" => report}, "token" => "garden-token")
    expect(result.to_json).not_to include(report, response_url, "garden-token")
    expect(result["text"]).to eq("[FILTERED]")
  end

  it "removes report data from Sentry error and transaction requests" do
    event = Sentry::ErrorEvent.new(configuration: Sentry.configuration)
    event.rack_env = Rack::MockRequest.env_for("https://example.test/mod")
    event.request.data = {"text" => report, "response_url" => response_url}
    event.request.query_string = "text=#{report}"
    event.request.headers = {"X-Slack-Signature" => "garden-signature"}
    event.request.env = {"response_url" => response_url}
    event.extra = {"report" => report}
    event.user = {"id" => "private-user"}
    [Sentry.configuration.before_send, Sentry.configuration.before_send_transaction].each do |scrub|
      result = scrub.call(event, {})
      expect(result.to_json_compatible.to_json).not_to include(report, response_url, "garden-signature", "private-user")
    end
  end

  it "does not collect HTTP or logging breadcrumbs" do
    expect(Sentry.configuration.breadcrumbs_logger).to be_empty
    crumb = Sentry::Breadcrumb.new(message: report, data: {"url" => response_url})
    expect(Sentry.configuration.before_breadcrumb.call(crumb, {})).to be_nil
    expect(Sentry.configuration.send_default_pii).to eq(false)
  end

  it "keeps test and development runs out of production error reporting" do
    expect(Sentry.configuration.enabled_environments).to eq(["production"])
  end

  it "logs only the error class and reference, not the original error or cause" do
    client = double("slack")
    allow(client).to receive(:chat_postMessage).and_raise(StandardError, "#{report} #{response_url}")
    expect(client).to receive(:chat_postEphemeral) do |args|
      expect(args[:text]).not_to include(report, response_url)
    end
    expect(Rails.logger).to receive(:error) do |message|
      expect(message).to match(/Slack operation failed: StandardError; reference=[a-f0-9]{16}/)
      expect(message).not_to include(report, response_url)
    end
    expect {
      Slack::Client.send_mod_message(user_id: "U123", channel_id: "C123", channel_name: "gardens", text: report, client: client)
    }.to raise_error(Slack::Client::RequestFailed) { |error| expect(error.cause).to be_nil }
  end
end
