# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :card_board_fish,
    country_codes: ["1", "46"],
    type: :card_board_fish,
    config: {
      username:  ENV["SMESS_CARD_BOARD_FISH_USER"],
      password:  ENV["SMESS_CARD_BOARD_FISH_PASS"]
    }
  })
end

@sms.output = :card_board_fish

@sms.message << " using CardBoardFish"

result = @sms.deliver
puts "---"
puts result