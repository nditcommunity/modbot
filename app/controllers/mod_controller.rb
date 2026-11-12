# Accepts webhooks from slack to post messages from users to the mod channel
class ModController < ApplicationController
  include SlackWebhook

  # Takes in params from webhook and sends a message to the mod channel
  #
  # @return [Status Code] should return a 202
  def create
    text = params[:text]
    return head(:bad_request) unless text.is_a?(String) && text.present? && text.length <= 12_000

    Slack::Client.send_mod_message(
      user_id: params[:user_id],
      channel_id: params[:channel_id],
      channel_name: params[:channel_name],
      text: params[:text]
    )

    head :accepted
  end
end
