# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :twilio_whatsapp,
    country_codes: ["1", "46"],
    type: :twilio_whatsapp,
    config: {
      sid:                    ENV["SMESS_TWILIO_SID"],
      auth_token:             ENV["SMESS_TWILIO_AUTH_TOKEN"],
      callback_url:           ENV["SMESS_TWILIO_CALLBACK_URL"],
      from:                   ENV["SMESS_TWILIO_WHATSAPP_FROM"]
    }
  })
end

@sms.output = :twilio_whatsapp

# default Twilio Whatsapp template
@sms.message = "Hi Human, were we able to solve the issue that you were facing?"

result = @sms.deliver
puts "---"
puts result

