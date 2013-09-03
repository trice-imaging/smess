require 'uri'
require 'httpi'

module Smess
  class GlobalMouth
    include Smess::Logging

    def deliver_sms(sms_arg)
      return false unless sms_arg.kind_of? Sms
      @sms = sms_arg

      generate_mac_hash
      request.url = "#{url}?#{params.to_query}"

      begin
        HTTPI.log_level = :debug
        response = HTTPI.get request
        result = normal_result(response)
      rescue Exception => e
        logger.warn response
        # connection problem or some error
        result = result_for_error(e)
      end
      result
    end

    private

    attr_reader :sms

    def username
      ENV["SMESS_GLOBAL_MOUTH_USER"].dup # paranoid safeguard
    end
    def password
      ENV["SMESS_GLOBAL_MOUTH_PASS"]
    end
    def sender_id
      ENV["SMESS_GLOBAL_MOUTH_SENDER_ID"]
    end

    def url
      "https://mcm.globalmouth.com:8443/api/mcm"
    end

    def from
      sms.originator || sender_id
    end

    def message_id
      @message_id ||= Digest::MD5.hexdigest "#{Time.now.strftime('%Y%m%d%H%M%S')}#{sms.to}-#{SecureRandom.hex(6)}"
    end

    def params
      @params ||= {
        username: username,
        msisdn: "+#{sms.to}",
        body: sms.message.strip_nongsm_chars.encode("ISO-8859-1"),
        originator: from,
        ref: message_id,
        dlr: "true"
      }
    end

    def compute_hash(values = [])
      hash = "#{username}#{values.join}"
      auth_hash = Digest::MD5.hexdigest "#{username}:#{password}"
      Digest::MD5.hexdigest "#{hash}#{auth_hash}"
    end

    def generate_mac_hash
      params[:hash] = compute_hash(
        [sms.message.strip_nongsm_chars.encode("ISO-8859-1"), params[:originator], params[:msisdn]]
      )
    end

    def request
      @request ||= HTTPI::Request.new
    end

    def result_for_error(e)
      code = e.code rescue "-1"
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
      response_code = response.body.split(/\n/).first
      response_code = "0" if response_code == "200"
      # Successful response
      {
        message_id: message_id,
        response_code: response_code.to_s,
        response: {body: response.body},
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