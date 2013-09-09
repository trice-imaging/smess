# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :twilio

@sms.message << " using Twilio"
#@sms.message << ". This tests a faked long message. This message will overflow the 160 character limit. It is sent as separate messages but should hopefully at least arrive in the correct order on the phone."

result = @sms.deliver
puts "---"
puts result

