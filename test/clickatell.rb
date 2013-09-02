# encoding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :clickatell

@sms.message << " using Clickatell"

result = @sms.deliver
puts "---"
puts result