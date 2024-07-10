require 'twilio-ruby'

module Smess
  class TwilioWhatsapp < Twilio

    private

    def to
      "whatsapp:+#{sms.to}"
    end

    def sender
      if from.present?
        {from: "whatsapp:+#{from}"}
      else
        super
      end
    end

  end
end