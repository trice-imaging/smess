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
      callback_url:           ENV["SMESS_TWILIO_CALLBACK_URL"]
    }
  })
end

@sms.output = :twilio

@sms.message << " using Twilio Messaging CoPilot"
#@sms.message << ". This tests a faked long message. This message will overflow the 160 character limit. It may be sent as separate messages but should in that case hopefully at least arrive in the correct order on the phone."

result = @sms.deliver
puts "---"
puts result

