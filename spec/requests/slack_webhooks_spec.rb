require "rails_helper"
require "openssl"

RSpec.describe "Slack webhooks", type: :request do
  let(:secret) { "garden-test-signing-secret" }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:body) { URI.encode_www_form(user_id: "U123", channel_id: "C123", channel_name: "gardens", text: "Garden planning", response_url: "https://example.test/private-response") }

  before do
    allow(Slack::Events.config).to receive(:signing_secret).and_return(secret)
    allow(Slack::Client).to receive(:send_mod_message)
    allow(Slack::Client).to receive(:add_user_to_channel)
  end

  def submit(path, payload: body, signed_body: payload, at: timestamp, signature: nil, extra_headers: {})
    signature ||= "v0=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "v0:#{at}:#{signed_body}")}"
    post path, params: payload, headers: {
      "CONTENT_TYPE" => "application/x-www-form-urlencoded",
      "HTTP_X_SLACK_REQUEST_TIMESTAMP" => at,
      "HTTP_X_SLACK_SIGNATURE" => signature
    }.merge(extra_headers)
  end

  ["/mod", "/channels"].each do |path|
    context path do
      it "accepts a correctly signed request" do
        submit(path)
        expect(response).to have_http_status(:accepted)
        expect(Slack::Client).to have_received((path == "/mod") ? :send_mod_message : :add_user_to_channel)
      end

      {
        "a forged signature" => {signature: "v0=invalid"},
        "an altered body" => {signed_body: "text=Original"},
        "a missing signature" => {extra_headers: {"HTTP_X_SLACK_SIGNATURE" => nil}},
        "a missing timestamp" => {at: nil},
        "a malformed timestamp" => {at: "garden"}
      }.each do |label, options|
        it "rejects #{label} without calling Slack" do
          submit(path, **options)
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to eq("")
          expect(Slack::Client).not_to have_received(:send_mod_message)
          expect(Slack::Client).not_to have_received(:add_user_to_channel)
        end
      end

      [-301, 301].each do |offset|
        it "rejects a timestamp outside the five-minute window (#{offset})" do
          submit(path, at: (Time.now.to_i + offset).to_s)
          expect(response).to have_http_status(:forbidden)
          expect(Slack::Client).not_to have_received(:send_mod_message)
          expect(Slack::Client).not_to have_received(:add_user_to_channel)
        end
      end

      it "fails closed when signing configuration is empty" do
        allow(Slack::Events.config).to receive(:signing_secret).and_return("")
        submit(path)
        expect(response).to have_http_status(:forbidden)
      end

      it "rejects structured command text" do
        submit(path, payload: "user_id=U123&channel_id=C123&channel_name=gardens&text[]=garden")
        expect(response).to have_http_status(:bad_request)
      end

      it "rejects oversized requests before dispatch or signature verification" do
        expect(Slack::Events::Request).not_to receive(:new)
        submit(path, payload: "text=#{"x" * WebhookBodyLimit::MAX_BYTES}")
        expect(response).to have_http_status(413)
      end
    end
  end

  it "rejects empty or overlong moderator reports" do
    ["", "x" * 12_001].each do |text|
      submit("/mod", payload: URI.encode_www_form(user_id: "U123", channel_id: "C123", channel_name: "gardens", text: text))
      expect(response).to have_http_status(:bad_request)
    end
    expect(Slack::Client).not_to have_received(:send_mod_message)
  end
end
