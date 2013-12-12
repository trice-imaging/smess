# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

@sms.output = :card_board_fish

@sms.message << " using CardBoardFish"

result = @sms.deliver
puts "---"
puts result