require 'uri'
require 'httpi'

module Smess
  class Smsglobal
    include Smess::Logging

    def deliver_sms(sms)
      return false unless sms.kind_of? Sms

      url = "https://www.smsglobal.com/http-api.php"
      from = sms.originator || ENV["SMESS_SMSGLOBAL_SENDER_ID"]

      params = {
        action: "sendsms",
        user: ENV["SMESS_SMSGLOBAL_USER"],
        password: ENV["SMESS_SMSGLOBAL_PASS"],
        from: from,
        to: sms.to,
        text: sms.message.strip_nongsm_chars,
        maxsplit: "3"
      }

      request = HTTPI::Request.new
      request.url = url
      request.body = params

      begin
        HTTPI.log_level = :debug
        response = HTTPI.post request

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
            text: sms.message.strip_nongsm_chars,
            from: from
          }
        }
      else
        first_response = response.body.split(/\r\n/).first.split(";")
        response_code = first_response.first.split(':').last.to_i
        message_id = first_response.last.split('SMSGlobalMsgID:').last

        # Successful response
        result = {
          message_id: message_id,
          response_code: response_code.to_s,
          response: response.body,
          destination_address: sms.to,
          data: {
            to: sms.to,
            text: sms.message.strip_nongsm_chars,
            from: from
          }
        }
      end
      result
    end

  end
end