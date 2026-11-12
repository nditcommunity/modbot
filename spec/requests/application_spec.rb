require "rails_helper"

RSpec.describe ApplicationController, type: :request do
  it "boots as the Slack Bot application without the unused job framework" do
    expect(Rails.application).to be_a(SlackBot::Application)
    expect(Rails.application.railties.map { |railtie| railtie.class.name }).not_to include("ActiveJob::Railtie")
  end

  it "serves the documentation link without creating a session" do
    allow(Sentry).to receive(:initialized?).and_return(false)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("https://github.com/nditcommunity/slack-bot#readme")
    expect(response.headers["Set-Cookie"]).to be_nil
  end
end
