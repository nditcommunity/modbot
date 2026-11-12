require "stringio"

# Runs before Rails or Sentry can parse an untrusted webhook body.
class WebhookBodyLimit
  MAX_BYTES = 64 * 1024

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless env["REQUEST_METHOD"] == "POST"

    length = env["CONTENT_LENGTH"]
    return reject(400) if length && !length.empty? && !length.match?(/\A\d+\z/)
    return reject(413) if length.to_i > MAX_BYTES

    input = env["rack.input"]
    if input
      body = +""
      while (chunk = input.read(MAX_BYTES + 1 - body.bytesize)) && !chunk.empty?
        body << chunk
        return reject(413) if body.bytesize > MAX_BYTES
      end

      # Preserve the exact bytes for Slack's HMAC, even for non-rewindable streams.
      env["rack.input"] = StringIO.new(body)
      env["CONTENT_LENGTH"] = body.bytesize.to_s
    end
    @app.call(env)
  end

  private

  def reject(status)
    [status, {"content-type" => "text/plain", "content-length" => "0"}, []]
  end
end
