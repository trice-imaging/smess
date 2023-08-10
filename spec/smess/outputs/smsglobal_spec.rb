require 'spec_helper'

describe Smess::Smsglobal, iso_id: "7.2.4" do

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
      username: "RspecUser",
      password: "RspecPass",
      sender_id: "RspecId"
    })
    output.sms = sms
    output
  }

  it 'sender_id overrides base class' do
    expect(subject.sender_id).to eq("RspecId")
    expect(described_class.new({username: "RspecUser", password: "RspecPass"}).sender_id).to eq("Smess")
  end

  it 'calls the correct http endpoint' do
    request = nil
    HTTPI.stub(:post) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "")
    }
    subject.deliver

    expect(request.url.scheme).to eq('https')
    expect(request.url.host).to eq('www.smsglobal.com')
    expect(request.url.port).to eq(443)
    expect(request.url.path).to eq('/http-api.php')
  end

  it 'generates correct data for a single message' do
    request = nil
    HTTPI.stub(:post) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "")
    }
    subject.deliver
    params = request.body

    expect(params).to match(/to=#{sms.to}/)
    expect(params).to match(/from=#{sms.originator}/)
  end

  it 'returns a response for a successful delivey' do
    body = "OK: 0; Sent queued message ID: 45f4039261456176 SMSGlobalMsgID:4222875942530091\r\n"
    request = nil
    HTTPI.stub(:post) { |r|
      request = r
      response = HTTPI::Response.new(200, [], body)
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("0")
    expect(results[:response]).to eq(body)
  end

  it 'returns a response for a failed delivey' do
    body = "ERROR: 102 SMSGlobalMsgID:\r\n"
    HTTPI.stub(:post) { |r|
      response = HTTPI::Response.new(200, [], body)
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("102")
    expect(results[:response]).to eq(body)
  end


  it 'does not swallow exceptions' do
    HTTPI.stub(:post) { |r|
      raise "Hell"
    }
    expect{
      results = subject.deliver
    }.to raise_error
  end

end