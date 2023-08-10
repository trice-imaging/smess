# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :twilio,
    country_codes: ["1", "46"],
    type: :twilio,
    config: {
      sid:                    ENV["SMESS_TWILIO_SID"],
      auth_token:             ENV["SMESS_TWILIO_AUTH_TOKEN"],
      messaging_service_sid:  ENV["SMESS_TWILIO_MSG_SERVICE_SID"],
      callback_url:           ENV["SMESS_TWILIO_CALLBACK_URL"],
      verify_service_sid:  ENV["SMESS_TWILIO_VERIFY_SERVICE_SID"]
    }
  })
end

@sms.output = :twilio

result = @sms.check("123456")
puts "---"
puts result

