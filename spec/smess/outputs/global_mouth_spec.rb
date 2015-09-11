require 'spec_helper'

describe Smess::GlobalMouth, iso_id: "7.2.4" do

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
      username: "",
      password: "",
      sender_id: ""
    })
    output.sms = sms
    output
  }

  it 'calls the correct http endpoint' do
    request = nil
    HTTPI.stub(:get) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "")
    }
    subject.deliver

    expect(request.url.scheme).to eq('https')
    expect(request.url.host).to eq('mcm.globalmouth.com')
    expect(request.url.port).to eq(8443)
    expect(request.url.path).to eq('/api/mcm')
  end

  it 'generates correct data for a single message' do
    request = nil
    HTTPI.stub(:get) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "200\n1")
    }
    subject.deliver
    params = request.url.query

    expect(params).to match(/msisdn=%2B#{sms.to}/)
    expect(params).to match(/originator=#{sms.originator}/)
  end

  it 'returns a response for a successful delivey' do
    body = "200\n1"
    request = nil
    HTTPI.stub(:get) { |r|
      request = r
      response = HTTPI::Response.new(200, [], body)
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("0")
    expect(results[:response][:body]).to eq(body)
  end

  it 'returns a response for a failed delivey' do
    body = "404\n1"
    HTTPI.stub(:get) { |r|
      response = HTTPI::Response.new(200, [], body)
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("404")
    expect(results[:response][:body]).to eq(body)
  end


  it 'returns a response for an exception' do
    HTTPI.stub(:get) { |r|
      raise "Hell"
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("-1")
  end

end