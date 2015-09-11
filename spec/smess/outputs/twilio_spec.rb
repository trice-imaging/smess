require 'spec_helper'

class FakeTwilioSender
  def create(data)
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

  subject {
    output = described_class.new({
      sid: "",
      auth_token: "",
      from: "",
      callback_url: ""
    })
    output.sms = sms
    output
  }

  it 'generates correct data for a single message' do
    request = nil
    subject.stub(:create_client_message) { |data|
      request = data
    }
    subject.deliver

    expect(request[:to]).to eq("+#{sms.to}")
    expect(request[:body]).to eq(sms.message)
  end

  it 'returns a response for an exception' do
    request = nil
    subject.stub(:create_client_message) { |data|
      raise "Hell"
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("-1")
  end

end