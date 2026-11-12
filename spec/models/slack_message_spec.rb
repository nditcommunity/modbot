require "rails_helper"

RSpec.describe SlackMessage do
  it "offers only the retained identity channels" do
    expect(SlackMessage::CHANNELS.keys).to eq [:bipoc, :women_nonbinary, :queer]
    expect(SlackMessage::CHANNELS[:women_nonbinary]).to eq(
      channel_id: "C067HKZ219C",
      description: "for women and nonbinary people"
    )
  end

  it "generates help from the available channels" do
    expected_text = "*bipoc:* for anyone who identifies as BIPOC\n" \
      "*women-nonbinary:* for women and nonbinary people\n" \
      "*queer:* for LGBTQIA+ folks"

    expect(SlackMessage.help_message).to eq [
      {
        type: "section",
        block_id: "help_message",
        text: {type: "mrkdwn", text: expected_text}
      }
    ]
  end

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
