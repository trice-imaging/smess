require 'uri'
require 'httpi'

module Smess
  class Smsglobal
    include Smess::Logging

    def deliver_sms(sms_arg)
      return false unless sms_arg.kind_of? Sms
      @sms = sms_arg

      request.url = url
      request.body = params

      begin
        HTTPI.log_level = :debug
        response = HTTPI.post request
        result = normal_result(response)
      rescue Exception => e
        puts logger.warn response
        # connection problem or some error
        result = result_for_error(e)
      end
      result
    end

    private

    attr_reader :sms

    def url
      "https://www.smsglobal.com/http-api.php"
    end

    def from
      sms.originator || ENV["SMESS_SMSGLOBAL_SENDER_ID"]
    end

    def params
      @params ||= {
        action: "sendsms",
        user: ENV["SMESS_SMSGLOBAL_USER"],
        password: ENV["SMESS_SMSGLOBAL_PASS"],
        from: from,
        to: sms.to,
        text: sms.message.strip_nongsm_chars,
        maxsplit: "3"
      }
    end

    def request
      @request ||= HTTPI::Request.new
    end

    def result_for_error(e)
      {
        response_code: '-1',
        response: {
          temporaryError: 'true',
          responseCode: e.code,
          responseText: e.message
        },
        data: result_data
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

    def result_data
      {
        to: sms.to,
        text: sms.message.strip_nongsm_chars,
        from: from
      }
    end

  end
end