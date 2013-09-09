require 'uri'
require 'httpi'

module Smess
  class Smsglobal < HttpBase

    def deliver
      request.url = url
      request.body = params

      begin
        HTTPI.log_level = :debug
        response = HTTPI.post request
        result = normal_result(response)
      rescue Exception => e
        logger.warn response
        # connection problem or some error
        result = result_for_error(e)
      end
      result
    end

    private

    def username
      ENV["SMESS_SMSGLOBAL_USER"]
    end
    def password
      ENV["SMESS_SMSGLOBAL_PASS"]
    end
    def sender_id
      ENV["SMESS_SMSGLOBAL_SENDER_ID"]
    end

    def url
      "https://www.smsglobal.com/http-api.php"
    end

    def params
      @params ||= {
        action: "sendsms",
        user: username,
        password: password,
        from: from,
        to: sms.to,
        text: sms.message.strip_nongsm_chars,
        maxsplit: "3"
      }
    end

    def normal_result(response)
      first_response = response.body.split(/\r\n/).first.split(";")
      response_code = first_response.first.split(':').last.to_i
      message_id = first_response.last.split('SMSGlobalMsgID:').last
      # Successful response
      {
        message_id: message_id,
        response_code: response_code.to_s,
        response: response.body,
        destination_address: sms.to,
        data: result_data
      }
    end

  end
end