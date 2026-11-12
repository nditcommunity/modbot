# Internal client that makes calls out to the [SlackWebClient](https://github.com/slack-ruby/slack-ruby-client)
module Slack
  class Client
    attr_reader :client

    class RequestFailed < StandardError; end

    SUPPORT_CHANNEL = "<#C068YBHSJRW>"

    # Gives user ability to add themselves to a private channel
    #
    # @param channel_name [String] text name of channel (ex: "_general")
    # @param user_id [String] slack user id of user who sent the message
    # @param channel_id [String] ID of the channel, ex: "C182938", found by looking at the URL when viewing a channel through a browser
    # @param client [Slack::Web::Client] the slack web client, defaults to nil
    def self.add_user_to_channel(user_id:, channel_id:, current_channel_name:, channel_name:, client: nil)
      client ||= default_client # if nil, set = to default
      channel_name = channel_name.to_s.strip.delete_prefix("#").downcase.tr("-", "_").delete_prefix("intersection_").to_sym
      begin
        if channel_name == :help
          post_ephemeral(
            channel_id: channel_id,
            user_id: user_id,
            channel_name: current_channel_name,
            client: client,
            blocks: SlackMessage.help_message
          )
        elsif SlackMessage::CHANNELS.include? channel_name
          client.conversations_invite(
            channel: SlackMessage::CHANNELS[channel_name][:channel_id],
            users: user_id
          )
        else
          post_ephemeral(
            channel_id: channel_id,
            user_id: user_id,
            channel_name: current_channel_name,
            client: client,
            message: "I could not find that channel. Please check the name against \"help\"."
          )
        end
      rescue Slack::Web::Api::Errors::ChannelNotFound
        post_ephemeral(
          channel_id: channel_id,
          user_id: user_id,
          channel_name: current_channel_name,
          client: client,
          message: "I could not find that channel. Please check the name against \"help\" or ask the mods for help in #{SUPPORT_CHANNEL}. Channel: #{channel_name}."
        )
      rescue Slack::Web::Api::Errors::AlreadyInChannel
        post_ephemeral(
          channel_id: channel_id,
          user_id: user_id,
          channel_name: current_channel_name,
          client: client,
          message: "Slack seems to think you are already in that channel! Please check your existing channel list for ##{channel_name}."
        )
      rescue => e
        fail_safely(e, channel_id: channel_id, user_id: user_id, channel_name: current_channel_name, client: client)
      end
    end

    def self.post_ephemeral(channel_id:, user_id:, channel_name:, client:, message: nil, blocks: nil)
      if channel_name == "directmessage"
        create_conversation(group: [user_id], text: message, client: client) if message
        create_conversation(group: [user_id], message: blocks, client: client) if blocks
      elsif message
        client.chat_postEphemeral(
          channel: channel_id,
          user: user_id,
          text: message
        )
      else
        client.chat_postEphemeral(
          channel: channel_id,
          user: user_id,
          blocks: blocks
        )
      end
    end

    # Opens a direct conversation and sends the supplied text or Block Kit message
    #
    # @param group [Array of Strings] array of group users, ex: ["U1234", "U2345", "U3456"]
    # @param message [JSON] can be passed in, must follow the Slack Block Kit format, defaults to nil
    def self.create_conversation(group:, text: nil, message: nil, client: nil)
      client ||= default_client
      conv = client.conversations_open(users: group.join(","))
      if text
        client.chat_postMessage(
          channel: conv.channel.id,
          text: text
        )
      else
        client.chat_postMessage(
          channel: conv.channel.id,
          blocks: message
        )
      end
    end

    # Given a user id, channel, and message text, it posts a message to the mod channel.
    #
    # @param user_id [String] slack user id of user who sent the message
    # @param channel_id [String] slack channel id where the user initially typed /mods
    # @param channel_name [String] slack channel name where user initially reached out to /mods
    # @param text [String] message text from user to mods
    def self.send_mod_message(user_id:, channel_id:, channel_name:, text:, client: nil)
      client ||= default_client
      begin
        client.chat_postMessage(
          channel: ENV["MOD_CHANNEL"],
          blocks: SlackMessage.mod_message(
            user_id: user_id,
            channel_id: channel_id,
            channel_name: channel_name,
            text: text
          )
        )
        post_ephemeral(
          channel_id: channel_id,
          user_id: user_id,
          channel_name: channel_name,
          client: client,
          message: "Your message has been sent to the mods."
        )
      rescue => e
        fail_safely(e, channel_id: channel_id, user_id: user_id, channel_name: channel_name, client: client)
      end
    end

    def self.fail_safely(error, **reply)
      reference = SecureRandom.hex(8)
      Rails.logger.error("Slack operation failed: #{error.class.name}; reference=#{reference}")
      begin
        post_ephemeral(**reply, message: "Something went wrong. Please ask the mods for help in #{SUPPORT_CHANNEL}. Reference: #{reference}.")
      rescue => notification_error
        Rails.logger.error("Slack error notification failed: #{notification_error.class.name}; reference=#{reference}")
      end
      # Do not pass the original message or cause into Rails/Sentry error reporting.
      raise RequestFailed, "Slack operation failed; reference=#{reference}", cause: nil
    end
    private_class_method :fail_safely

    private_class_method

    def self.default_client
      ::Slack::Web::Client.new(token: ENV["SLACK_OAUTH_TOKEN"])
    end
  end
end
