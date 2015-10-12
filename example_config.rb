most_of_the_caribbean = [
  "1242", # Bahamas
  "1246", # Barbados
  "1264", # Anguilla
  "1268", # Antigua and Barbuda
  "1284", # British Virgin Islands
  "1345", # Cayman Islands
  "1473", # Grenada
  "1649", # Turks and Caicos Islands
  "1664", # Montserrat
  "1670", # Northern Mariana Islands
  "1671", # Guam
  "1684", # American Samoa
  "1758", # Saint Lucia
  "1767", # Dominica
  "1784", # Saint Vincent and the Grenadines
  "1787", # Puerto Rico
  "1809", # Dominican Republic
  "1868", # Trinidad and Tobago
  "1869", # Saint Kitts and Nevis
  "1876"  # Jamaica
]

Smess.configure do |config|

  config.default_sender_id = ENV["SMESS_SENDER_ID"]
  config.default_output = :global_mouth
  config.register_output({
    name: :global_mouth,
    country_codes: most_of_the_caribbean + ["20", "33", "34", "44", "46", "49", "594", "966"],
    type: :global_mouth,
    config: {
      username:  ENV["SMESS_GLOBAL_MOUTH_USER"],
      password:  ENV["SMESS_GLOBAL_MOUTH_PASS"],
      sender_id: ENV["SMESS_GLOBAL_MOUTH_SENDER_ID"]
    }
  })

  config.register_output({
    name: :iconectiv,
    country_codes: ["1"],
    type: :iconectiv,
    config: {
      sms_url:                       ENV["SMESS_ICONECTIV_URL"],
      username:                      ENV["SMESS_ICONECTIV_USER"],
      password:                      ENV["SMESS_ICONECTIV_PASS"],
      shortcode:                     ENV["SMESS_ICONECTIV_SHORTCODE"],
      account_name:                  ENV["SMESS_ICONECTIV_ACCOUNT_NAME"],
      service_name:                  ENV["SMESS_SERVICE_NAME"],
      service_meta_data_verizon:     ENV["SMESS_ICONECTIV_SERVICE_META_DATA_VERIZON"],
      service_meta_data_t_mobile_us: ENV["SMESS_ICONECTIV_SERVICE_META_DATA_T_MOBILE_US"]
    }
  })

  config.register_output({
    name: :twilio,
    country_codes: ["971"],
    type: :twilio,
    config: {
      sid:          ENV["SMESS_TWILIO_SID"],
      auth_token:   ENV["SMESS_TWILIO_AUTH_TOKEN"],
      from:         ENV["SMESS_TWILIO_FROM"],
      callback_url: ENV["SMESS_TWILIO_CALLBACK_URL"]
    }
  })

  config.register_output({
    name: :card_board_fish,
    country_codes: ["212"],
    type: :card_board_fish,
    config: {
      username:  ENV["SMESS_CARD_BOARD_FISH_USER"],
      password:  ENV["SMESS_CARD_BOARD_FISH_PASS"]
    }
  })

  config.register_output({
    name: :clickatell,
    country_codes: ["1441"],
    type: :clickatell,
    config: {
      api_id:     ENV["SMESS_CLICKATELL_API_ID"],
      user:       ENV["SMESS_CLICKATELL_USER"],
      pass:       ENV["SMESS_CLICKATELL_PASS"],
      sender_id:  ENV["SMESS_CLICKATELL_SENDER_ID"],
      sender_ids: ENV["SMESS_CLICKATELL_SENDER_IDS"]
    }
  })

end
