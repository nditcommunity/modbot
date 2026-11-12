module SlackWebhook
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_signature
    before_action :validate_slack_fields
  end

  private

  def validate_slack_fields
    valid = params[:user_id].is_a?(String) && params[:user_id].match?(/\A[UW][A-Z0-9]+\z/) &&
      params[:channel_id].is_a?(String) && params[:channel_id].match?(/\A[CGD][A-Z0-9]+\z/) &&
      params[:channel_name].is_a?(String) && params[:text].is_a?(String)
    head :bad_request unless valid
  end

  def verify_webhook_signature
    secret = Slack::Events.config.signing_secret
    return head(:forbidden) if secret.blank?

    timestamp = request.get_header("HTTP_X_SLACK_REQUEST_TIMESTAMP")
    return head(:forbidden) unless timestamp.to_s.match?(/\A\d+\z/)

    Slack::Events::Request.new(request).verify!
  rescue Slack::Events::Request::InvalidSignature, Slack::Events::Request::TimestampExpired
    head :forbidden
  end
end
