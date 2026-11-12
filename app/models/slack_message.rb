# Slack message templates built initially using the [Slack Block Kit Builder](https://api.slack.com/block-kit)
module SlackMessage
  module_function

  # constant for channel ids and descriptions for identity channels
  CHANNELS = {
    bipoc: {channel_id: "C06V26ZBMQA", description: "for anyone who identifies as BIPOC"},
    women_nonbinary: {channel_id: "C067HKZ219C", description: "for women and nonbinary people"},
    queer: {channel_id: "C067M825K6Z", description: "for LGBTQIA+ folks"}
  }

  # Generates help message for identity channels
  #
  # @return [JSON] message content fitting Slack's block kit requirements
  def help_message
    [
      {
        type: "section",
        block_id: "help_message",
        text: {
          type: "mrkdwn",
          text: CHANNELS.map { |name, channel| "*#{name.to_s.tr("_", "-")}:* #{channel[:description]}" }.join("\n")
        }
      }
    ]
  end

  # Generates a message to the mod channel
  #
  # @param user_id [String] slack user id of user sending message to mods
  # @param channel_id [String] slack channel id user is sending message from
  # @param channel_name [String] slack channel name where user initially reached out to /mods
  # @param text [String] text of message
  # @return [JSON] message content fitting Slack's block kit requirements
  def mod_message(user_id:, channel_id:, channel_name:, text:)
    raise ArgumentError, "Report must contain 1–12,000 characters" unless text.is_a?(String) && text.present? && text.length <= 12_000

    header = "Message from <@#{ERB::Util.html_escape(user_id)}> in <##{ERB::Util.html_escape(channel_id)}>"
    [
      {
        type: "section",
        block_id: "mod_message",
        text: {type: "mrkdwn", text: header}
      },
      *text.chars.each_slice(3_000).map.with_index do |characters, index|
        {
          type: "section",
          block_id: "mod_report_#{index}",
          text: {type: "plain_text", text: characters.join, emoji: false}
        }
      end
    ]
  end
end
