require 'spec_helper'

describe Smess::Auto, iso_id: "7.2" do

  let(:auto){ Smess::Auto.new }

  it 'get_output_name_for_msisdn returns an aggregator from the registry based on the countrycode' do
    auto.get_output_name_for_msisdn("12345677889").should == Smess::OUTPUT_BY_COUNTRY_CODE["1"]
    auto.get_output_name_for_msisdn("46123456778").should == Smess::OUTPUT_BY_COUNTRY_CODE["46"]
    auto.get_output_name_for_msisdn("97112345677").should == Smess::OUTPUT_BY_COUNTRY_CODE["971"]
  end

  it 'get_output_name_for_msisdn handles quirky american countrycodes' do
    auto.get_output_name_for_msisdn("16841234567").should == Smess::OUTPUT_BY_COUNTRY_CODE["1684"]
    auto.get_output_name_for_msisdn("12641234567").should == Smess::OUTPUT_BY_COUNTRY_CODE["1264"]
  end

  it 'get_output_name_for_msisdn returns the default aggregator based on the countrycode we dont specify' do
    auto.get_output_name_for_msisdn("99912345677").should == Smess::OUTPUT_BY_COUNTRY_CODE["0"]
  end

end