# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :iconectiv,
    country_codes: ["1", "46"],
    type: :iconectiv,
    config: {
      sms_url:                       ENV["SMESS_ICONECTIV_URL"],
      username:                      ENV["SMESS_ICONECTIV_USER"],
      password:                      ENV["SMESS_ICONECTIV_PASS"],
      shortcode:                     ENV["SMESS_ICONECTIV_SHORTCODE"],
      account_name:                  ENV["SMESS_ICONECTIV_ACCOUNT_NAME"],
      service_name:                  ENV["SMESS_SERVICE_NAME"],
      service_meta_data_verizon:     ENV["SMESS_ICONECTIV_SERVICE_META_DATA_VERIZON"],
      service_meta_data_t_mobile_us: ENV["SMESS_ICONECTIV_SERVICE_META_DATA_T_MOBILE_US"]
    }
  })
end

@sms.output = :iconectiv

@sms.message << " using iConectiv."
#@sms.message << ". This tests a long concatenated message. This message will overflow the 160 character limit. It is sent as separate messages but it should still be glued together to a single message on the phone."

result = @sms.deliver
puts "---"
puts result