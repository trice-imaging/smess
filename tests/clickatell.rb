# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :clickatell

@sms.message << " using Clickatell"
#@sms.message << ". This tests a long concatenated message. This message will overflow the 160 character limit. It is sent as separate messages but it should still be glued together to a single message on the phone."


result = @sms.deliver
puts "---"
puts result