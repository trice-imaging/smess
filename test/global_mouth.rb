# encoding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :global_mouth

@sms.message << " using GlobalMouth"

result = @sms.deliver
puts "---"
puts result