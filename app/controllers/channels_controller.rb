# Accepts webhooks from slack so users can add themselves to private channels
class ChannelsController < ApplicationController
  include SlackWebhook

  # Takes in params from webhook and adds user to channel
  #
  # @return [Status Code] should return a 202
  def create
    Slack::Client.add_user_to_channel(
      user_id: params[:user_id],
      channel_id: params[:channel_id],
      channel_name: params[:text],
      current_channel_name: params[:channel_name]
    )

    head :accepted
  end
end
