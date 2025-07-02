require 'spec_helper'

class FakeTwilioSender
  def create(data)
  end
end

class FakeTwilioResponse
  def sid
    "SM727fd423411e4b1b8dcdc4d48ee07f20"
  end
  def status
    "accepted"
  end
  def error_code
    nil
  end
  def error_message
    nil
  end
  def price
    nil
  end
  def price_unit
    nil
  end
  def num_segments
    nil
  end
end

describe Smess::Twilio, iso_id: "7.2.4" do

  let(:sms) {
    Smess::Sms.new(
      to: '46701234567',
      message: 'Test SMS',
      originator: 'TestSuite',
      output: "test"
    )
  }

  let(:concat_sms) {
    Smess::Sms.new(
      to: '46701234567',
      message: 'This tests a long concatenated message. This message will overflow the 160 character limit. It is sent as separate messages but it should still be glued together to a single message on the phone.',
      originator: 'TestSuite',
      output: "test"
    )
  }

  let(:sms_with_callback_params) {
    Smess::Sms.new(
      to: '46701234567',
      message: 'Test SMS',
      originator: 'TestSuite',
      output: "test",
      callback_params: {foo: "bar"}
    )
  }

  subject {
    output = described_class.new({
      sid: "",
      auth_token: "a",
      from: "",
      callback_url: ""
    })
    output.sms = sms
    output
  }

  it 'generates correct data for a single message' do
    request = nil
    allow(subject).to receive(:create_client_message) { |data|
      request = data
      FakeTwilioResponse.new
    }
    subject.deliver

    expect(request[:to]).to eq("+#{sms.to}")
    expect(request[:body]).to eq(sms.message)
  end

  it 'does not swallow exceptions' do
    request = nil
    allow(subject).to receive(:create_client_message) { |data|
      raise "Hell"
    }
    expect{
      results = subject.deliver
    }.to raise_error(RuntimeError, "Hell")

  end

  describe "per-sms callback params" do
    it 'adds nothing to an empty callback url' do
      subject.sms = sms_with_callback_params
      expect(subject.send(:dynamic_callback_url)).to eq("")
      
    end

    it 'adds params to callback url' do
      subject.callback_url = "http://foo.com/callback"
      subject.sms = sms_with_callback_params
      expect(subject.send(:dynamic_callback_url)).to eq("http://foo.com/callback?foo=bar")
    end

    it 'merges params intoto callback url with existing params' do
      subject.callback_url = "http://foo.com/callback?bat=baz"
      subject.sms = sms_with_callback_params
      expect(subject.send(:dynamic_callback_url)).to eq("http://foo.com/callback?bat=baz&foo=bar")
    end
  end
end
