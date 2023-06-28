require 'spec_helper'

describe Smess::Auto, iso_id: "7.2.1" do
  describe '#get_output_name_for_msisdn' do
    subject { Smess::Auto.new(Smess::Sms.new).get_output_name_for_msisdn(@msisdn) }

    it 'returns USA aggregator from the registry based on the single digit countrycode' do
      @msisdn = "12345677889"
      should == Smess.config.output_by_country_code["1"]
    end

    it 'returns Swedish aggregator from the registry based on the 2 digit countrycode' do
      @msisdn = "46123456778"
      should == Smess.config.output_by_country_code["46"]
    end

    it 'returns UAE aggregator from the registry based on the 3 digit countrycode' do
      @msisdn = "97112345677"
      should == Smess.config.output_by_country_code["971"]
    end

    it 'handles quirky american countrycodes, part 1: Samoa' do
      @msisdn = "16841234567"
      should == Smess.config.output_by_country_code["1684"]
    end

    it 'handles quirky american countrycodes, part 2: Anguilla' do
      @msisdn = "12641234567"
      should == Smess.config.output_by_country_code["1264"]
    end

    it 'returns the default aggregator based on the countrycode we dont specify' do
      @msisdn = "99912345677"
      should == Smess.config.default_output
    end

  end

  describe '#output_for' do

    before(:each) do
      Smess.reset_config
      Smess.configure do |config|

        config.default_output = :test

        config.register_output({
          name: :global_mouth,
          country_codes: ["1", "46"],
          type: :global_mouth,
          config: {
            username:  "",
            password:  "",
            sender_id: ""
          }
        })

        config.register_output({
          name: :twilio,
          country_codes: ["971", "46"],
          type: :twilio,
          config: {
            sid:          "",
            auth_token:   "a",
            from:         "",
            callback_url: ""
          }
        })

      end
    end

    subject { Smess::Auto.new(Smess::Sms.new).output_for(@msisdn) }

    it 'returns USA aggregator from the registry based on the single digit countrycode' do
      @msisdn = "12345677889"
      output_name = subject.class.name.split('::').last.smess_to_underscore.to_sym
      output_name == Smess.config.output_by_country_code["1"]
    end

    it 'returns Swedish aggregator from the registry based on the 2 digit countrycode' do
      @msisdn = "46123456778"
      output_name = subject.class.name.split('::').last.smess_to_underscore.to_sym
      output_name == Smess.config.output_by_country_code["46"]
    end

    it 'returns UAE aggregator from the registry based on the 3 digit countrycode' do
      @msisdn = "97112345677"
      output_name = subject.class.name.split('::').last.smess_to_underscore.to_sym
      output_name == Smess.config.output_by_country_code["971"]
    end

    it 'handles quirky american countrycodes, part 1: Samoa' do
      @msisdn = "16841234567"
      output_name = subject.class.name.split('::').last.smess_to_underscore.to_sym
      output_name == Smess.config.output_by_country_code["1684"]
    end

    it 'handles quirky american countrycodes, part 2: Anguilla' do
      @msisdn = "12641234567"
      output_name = subject.class.name.split('::').last.smess_to_underscore.to_sym
      output_name == Smess.config.output_by_country_code["1264"]
    end

    it 'returns the default aggregator based on the countrycode we dont specify' do
      @msisdn = "99912345677"
      output_name = subject.class.name.split('::').last.smess_to_underscore.to_sym
      output_name == Smess.config.default_output
    end

  end

  describe '#deliver' do
    let(:sms){ Smess::Sms.new(to:"99912345677") }
    subject {
      output = Smess::Auto.new({})
      output.sms = sms
      output
    }

    it 'asks for an output class for msisdn and calls deliver on it' do
      result = subject.deliver
      Smess::Test.instance.sms.should == sms
    end

    it 'asks for an output class for msisdn and calls deliver on it' do
      result = sms.deliver
      expect(result[:sent_with]).to eq(:test)
    end

  end

end