require 'spec_helper'

describe Smess::Mblox, iso_id: "7.2.8" do

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

  subject { described_class.new(sms) }

  it 'calls the correct http endpoint' do
    request = nil
    HTTPI.stub(:post) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "")
    }
    subject.deliver
    expect(request.url.to_s).to eq('https://xml4.us.mblox.com/send')
  end

  it 'sets correct content type' do
    request = nil
    HTTPI.stub(:post) { |r|
      request = r
      response = HTTPI::Response.new(200, [], "")
    }
    subject.deliver
    expect(request.headers["Content-Type"]).to eq("application/x-www-form-urlencoded")
  end

  it 'generates correct xml data for a single message' do
    xml_data = nil
    HTTPI.stub(:post) { |r|
      response = HTTPI::Response.new(200, [], "")
    }
    subject.stub(:xml_data_for) { |xml_params|
      xml_data = subject.hash_data_for(xml_params)
      '<?xml version="1.0"?><nothing></nothing>'
    }
    subject.deliver
    # one expectation per it statement? eh... close enough.
    expect(xml_data[:notification_request][:notification_header][:partner_name]).to eq(ENV["SMESS_MBLOX_SURE_ROUTE_USER"])
    expect(xml_data[:notification_request][:notification_header][:partner_password]).to eq(ENV["SMESS_MBLOX_SURE_ROUTE_PASS"])
    expect(xml_data[:notification_request][:notification_list][:notification][:message]).to eq(sms.message)
    expect(xml_data[:notification_request][:notification_list][:notification][:profile]).to eq(ENV["SMESS_MBLOX_SURE_ROUTE_PROFILE_ID"])
    expect(xml_data[:notification_request][:notification_list][:notification][:sender_i_d]).to eq(ENV["SMESS_MBLOX_SURE_ROUTE_SHORTCODE"])
    expect(xml_data[:notification_request][:notification_list][:notification][:subscriber][:subscriber_number]).to eq(sms.to)
    expect(xml_data[:notification_request][:notification_list][:notification][:service_id]).to eq(ENV["SMESS_MBLOX_SURE_ROUTE_SID"])
  end

  it 'generates correct udh data for a long concatenated message' do
    xml_datas = []
    HTTPI.stub(:post) { |r|
      response = HTTPI::Response.new(200, [], "")
    }
    subject2 = described_class.new(concat_sms)
    subject2.stub(:xml_data_for) { |xml_params|
      xml_datas << subject2.hash_data_for(xml_params)
      '<?xml version="1.0"?><nothing></nothing>'
    }
    subject2.deliver
    message = xml_datas.first[:notification_request][:notification_list][:notification][:message] + xml_datas.last[:notification_request][:notification_list][:notification][:message]

    # one expectation per it statement? eh... close enough.
    expect(xml_datas.length).to eq(2)
    expect(xml_datas.first[:notification_request][:notification_list][:notification][:udh]).to match(/:05:00:03:[a-f0-9]{2}:02:01/)
    expect(xml_datas.last[:notification_request][:notification_list][:notification][:udh]).to match(/:05:00:03:[a-f0-9]{2}:02:02/)
    expect(message).to eq(concat_sms.message)
  end

end