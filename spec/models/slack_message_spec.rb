require "rails_helper"

RSpec.describe SlackMessage do
  it "generates mod message" do
    message = SlackMessage.mod_message(user_id: "U123", channel_id: "C123", channel_name: "fun_times", text: "something not great happened.")
    expected_message = [
      {
        type: "section",
        block_id: "mod_message",
        text: {
          type: "mrkdwn",
          text: "Message from <@U123>
in <#C123> (fun_times):
something not great happened."
        }
      }
    ]
    expect(message).to eq expected_message
  end
end
