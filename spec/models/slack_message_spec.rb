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

  it "keeps report text literal, without mentions or Slack formatting" do
    text = "Garden <!channel> <@U456> <https://example.test|flowers> & 🌱"
    message = SlackMessage.mod_message(user_id: "U123", channel_id: "C123", channel_name: "gardens", text: text)
    expect(message.first[:text]).to eq(type: "mrkdwn", text: "Message from <@U123> in <#C123>")
    expect(message.last[:text]).to eq(type: "plain_text", text: text, emoji: false)
  end

  it "splits long Unicode reports without truncation or oversized blocks" do
    text = "🌱" * 7_000
    message = SlackMessage.mod_message(user_id: "U123", channel_id: "C123", channel_name: "gardens", text: text)
    reports = message.drop(1).map { |block| block[:text][:text] }
    expect(reports.map(&:length)).to eq([3_000, 3_000, 1_000])
    expect(reports.join).to eq(text)
  end

  it "rejects empty, structured, or overlong reports" do
    ["", nil, [], "x" * 12_001].each do |text|
      expect { SlackMessage.mod_message(user_id: "U123", channel_id: "C123", channel_name: "gardens", text: text) }.to raise_error(ArgumentError)
    end
  end
end
