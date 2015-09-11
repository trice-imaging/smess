# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :global_mouth,
    country_codes: ["1", "46"],
    type: :global_mouth,
    config: {
      username:  ENV["SMESS_GLOBAL_MOUTH_USER"],
      password:  ENV["SMESS_GLOBAL_MOUTH_PASS"],
      sender_id: ENV["SMESS_GLOBAL_MOUTH_SENDER_ID"]
    }
  })
end

@sms.output = :global_mouth

@sms.message << " using GlobalMouth"

result = @sms.deliver
puts "---"
puts result