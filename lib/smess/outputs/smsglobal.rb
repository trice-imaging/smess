require 'uri'
require 'httpi'

module Smess
  class Smsglobal < HttpBase

    def deliver
      request.url = url
      request.body = params

      http_post request
    end

    attr_accessor :username, :password, :sender_id
    def validate_config
      @username = config.fetch(:username)
      @password = config.fetch(:password)
      @sender_id = config.fetch(:sender_id, Smess.config.default_sender_id)
    end

    private

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