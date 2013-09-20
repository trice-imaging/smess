# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :etisalatdemo

@sms.message << " using Etisalat"

result = @sms.deliver
puts "---"
puts result