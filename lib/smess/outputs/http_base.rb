require 'uri'
require 'httpi'

module Smess
  class HttpBase < Output
    include Smess::Logging

    def initialize(config)
      super
      HTTPI.log_level = :debug
    end

    private

    attr_reader :sms

    def sender_id
      ENV["SMESS_SENDER_ID"]
    end

    def from
      sms.originator || sender_id
    end

    def message_id
      @message_id ||= Digest::MD5.hexdigest "#{Time.now.strftime('%Y%m%d%H%M%S')}#{sms.to}-#{SecureRandom.hex(6)}"
    end

    def request
      @request ||= HTTPI::Request.new
    end

    def http_get(request)
      http_request(:get, request)
    end

    def http_post(request)
      http_request(:post, request)
    end

    def http_request(method, request)
      response = HTTPI.send(method, request)
      normal_result(response)
    rescue => e
      logger.warn response
      result_for_error(e)
    end

    def result_for_error(e)
      {
        response_code: '-1',
        response: {
          temporaryError: 'true',
          responseCode: '-1',
          responseText: e.message
        },
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