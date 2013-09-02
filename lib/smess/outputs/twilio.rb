require 'twilio-ruby'

module Smess
  class Twilio
    include Smess::Logging

    def deliver_sms(sms)
      return false unless sms.kind_of? Sms

      parts = Smess.separate_sms sms.message.strip_nongsm_chars
      return false if parts[0].empty?

      @client = ::Twilio::REST::Client.new(ENV["SMESS_TWILIO_SID"], ENV["SMESS_TWILIO_AUTH_TOKEN"])


      results = []
      while parts.length > 0
        results << send_one_sms(sms, parts.shift)
      end
      results[0][:data][:text] = sms.message.strip_nongsm_chars
      results[0]
    end

    def send_one_sms(sms, message)
      begin
        response = @client.account.sms.messages.create({
          from: ENV["SMESS_TWILIO_FROM"],
          to: "+#{sms.to}",
          body: message,
          status_callback: ENV["SMESS_TWILIO_CALLBACK_URL"]
        })
      rescue Exception => e
        logger.warn response
        # connection problem or some error
        result = {
          response_code: '-1',
          response: {
            temporaryError: 'true',
            responseCode: e.code,
            responseText: e.message
          },
          data: {
            to: sms.to,
            text: message,
            from: ENV["SMESS_TWILIO_FROM"]
          }
        }
      else
        response_code = response.status
        response_code = "0" unless response.status == "failed"
        # Successful response
        result = {
          message_id: response.sid,
          response_code: response_code.to_s,
          response: MultiJson.load(@client.last_response.body),
          destination_address: sms.to,
          data: {
            to: sms.to,
            text: message,
            from: ENV["SMESS_TWILIO_FROM"]
          }
        }
      end
      result
    end


  end
end