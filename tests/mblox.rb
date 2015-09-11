# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :mblox,
    country_codes: ["1", "46"],
    type: :mblox,
    config: {
      username:   ENV["SMESS_MBLOX_SURE_ROUTE_USER"],
      password:   ENV["SMESS_MBLOX_SURE_ROUTE_PASS"],
      shortcode:  ENV["SMESS_MBLOX_SURE_ROUTE_SHORTCODE"],
      profile_id: ENV["SMESS_MBLOX_SURE_ROUTE_PROFILE_ID"],
      sid:        ENV["SMESS_MBLOX_SURE_ROUTE_SID"]
    }
  })
end





@sms.output = :mblox

@sms.message << " using mBlox"
#@sms.message << ". This tests a long concatenated message. This message will overflow the 160 character limit. It is sent as separate messages but it should still be glued together to a single message on the phone."

result = @sms.deliver
puts "---"
puts result

