# encoding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :ipxus

@sms.message << " using IPX"

result = @sms.deliver
puts "---"
puts result