require 'twilio-ruby'

module Smess
  class TwilioWhatsapp < Twilio

    private

    def to
      "whatsapp:#{sms.to}"
    end

    def sender
      {from: "whatsapp:#{from}"}
    end

  end
end
