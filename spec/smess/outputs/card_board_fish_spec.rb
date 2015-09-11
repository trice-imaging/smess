require 'spec_helper'

describe Smess::CardBoardFish do

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
      password: ""
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
    expect(request.url.host).to eq('sms2.cardboardfish.com')
    expect(request.url.port).to eq(9444)
    expect(request.url.path).to eq('/HTTPSMS')
  end

  it 'generates correct data for a single message' do
    request = nil
    HTTPI.stub(:get) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "200\n1")
    }
    subject.deliver
    params = request.url.query

    expect(params).to match(/S=H/)
    expect(params).to match(/UN=/)
    expect(params).to match(/P=/)
    expect(params).to match(/DA=#{sms.to}/)
    expect(params).to match(/SA=#{sms.originator}/)
    expect(params).to match(/M=/)
  end

  it 'returns a response for a successful delivey' do
    body = "OK 3583910"
    request = nil
    HTTPI.stub(:get) { |r|
      request = r
      response = HTTPI::Response.new(200, [], body)
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("0")
    expect(results[:response][:body]).to eq(body)
  end

  it 'returns a response for a successful delivey including user reference' do
    body = "OK 3583910 UR:JBD829SSA"
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
    body = "ERR -10"
    HTTPI.stub(:get) { |r|
      response = HTTPI::Response.new(401, [], body)
    }
    results = subject.deliver

    expect(results[:response_code]).to eq("401")
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