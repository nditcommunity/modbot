require "rails_helper"

RSpec.describe WebhookBodyLimit do
  let(:app) { ->(env) { [200, {}, [env["rack.input"].read]] } }
  subject(:middleware) { described_class.new(app) }

  def env(body, length: body.bytesize.to_s)
    {"REQUEST_METHOD" => "POST", "CONTENT_LENGTH" => length, "rack.input" => StringIO.new(body)}
  end

  it "keeps exact raw bytes for signature verification" do
    body = "text=Garden+%26+flowers%0Ahello"
    expect(middleware.call(env(body))).to eq([200, {}, [body]])
  end

  it "accepts the boundary and rejects one extra byte" do
    expect(middleware.call(env("x" * described_class::MAX_BYTES)).first).to eq(200)
    expect(middleware.call(env("x" * (described_class::MAX_BYTES + 1))).first).to eq(413)
  end

  it "bounds actual reads when Content-Length is missing or too small" do
    [nil, "1"].each do |length|
      input = StringIO.new("x" * (described_class::MAX_BYTES + 100))
      expect(input).to receive(:read).with(described_class::MAX_BYTES + 1).and_call_original
      expect(middleware.call(env("", length: length).merge("rack.input" => input)).first).to eq(413)
    end
  end

  it "rejects a declared oversized body without reading it" do
    input = double("input")
    expect(input).not_to receive(:read)
    expect(middleware.call(env("", length: "999999").merge("rack.input" => input)).first).to eq(413)
  end

  it "rejects invalid content lengths" do
    ["-1", "garden"].each do |length|
      expect(middleware.call(env("", length: length)).first).to eq(400)
    end
  end
end
