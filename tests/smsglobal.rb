# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :smsglobal,
    country_codes: ["1", "46"],
    type: :smsglobal,
    config: {
      username:  ENV["SMESS_SMSGLOBAL_USER"],
      password:  ENV["SMESS_SMSGLOBAL_PASS"],
      sender_id: ENV["SMESS_SMSGLOBAL_SENDER_ID"]
    }
  })
end

@sms.output = :smsglobal

@sms.message << " using SMSGlobal"

result = @sms.deliver
puts "---"
puts result