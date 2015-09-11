# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :clickatell,
    country_codes: ["1", "46"],
    type: :clickatell,
    config: {
      api_id:     ENV["SMESS_CLICKATELL_API_ID"],
      user:       ENV["SMESS_CLICKATELL_USER"],
      pass:       ENV["SMESS_CLICKATELL_PASS"],
      sender_id:  ENV["SMESS_CLICKATELL_SENDER_ID"],
      sender_ids: ENV["SMESS_CLICKATELL_SENDER_IDS"]
    }
  })
end


@sms.output = :clickatell

@sms.message << " using Clickatell"
#@sms.message << ". This tests a long concatenated message. This message will overflow the 160 character limit. It is sent as separate messages but it should still be glued together to a single message on the phone."


result = @sms.deliver
puts "---"
puts result