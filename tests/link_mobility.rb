# coding: UTF-8
require File.expand_path("../test_setup", __FILE__)

Smess.configure do |config|
  config.register_output({
    name: :link_mobility,
    country_codes: ["1", "46"],
    type: :link_mobility,
    config: {
      url:                 ENV["SMESS_LINKMOBILITY_URL"],
      username:            ENV["SMESS_LINKMOBILITY_USER"],
      password:            ENV["SMESS_LINKMOBILITY_PASS"],
      platform_id:         ENV["SMESS_LINKMOBILITY_PLATFORM_ID"],
      platform_partner_id: ENV["SMESS_LINKMOBILITY_PLATFORM_PARTNER_ID"],
      gate_id:             ENV["SMESS_LINKMOBILITY_GATE_ID"]
    }
  })
end

Smess.configure do |config|
  config.register_output({
    name: :link_mobility_uk,
    country_codes: ["46"],
    type: :link_mobility,
    config: {
      url:                 ENV["SMESS_LINKMOBILITY_URL"],
      username:            ENV["SMESS_LINKMOBILITY_USER"],
      password:            ENV["SMESS_LINKMOBILITY_PASS"],
      platform_id:         ENV["SMESS_LINKMOBILITY_PLATFORM_ID"],
      platform_partner_id: ENV["SMESS_LINKMOBILITY_PLATFORM_PARTNER_ID"],
      gate_id:             ENV["SMESS_LINKMOBILITY_GATE_ID"],
      sender_id:         ENV["SMESS_LINKMOBILITY_LONG_NUMBER"]
    }
  })
end


@sms.output = :link_mobility

@sms.message << " using Link Mobility"

result = @sms.deliver
puts "---"
puts result
