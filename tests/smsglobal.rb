# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :smsglobal

@sms.message << " using SMSGlobal"

result = @sms.deliver
puts "---"
puts result