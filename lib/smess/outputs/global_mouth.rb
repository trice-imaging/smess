require 'uri'
require 'httpi'

module Smess
  class GlobalMouth
    include Smess::Logging


    def compute_hash(values = [])
      hash = "#{username}#{values.join}"
      auth_hash = Digest::MD5.hexdigest "#{username}:#{password}"
      Digest::MD5.hexdigest "#{hash}#{auth_hash}"
    end


    def deliver_sms(sms)
      return false unless sms.kind_of? Sms

      url = "https://mcm.globalmouth.com:8443/api/mcm"
      from = sms.originator || sender_id
      message_id = Digest::MD5.hexdigest "#{Time.now.strftime('%Y%m%d%H%M%S')}#{sms.to}-#{SecureRandom.hex(6)}"

      params = {
        username: username,
        msisdn: "+#{sms.to}",
        body: sms.message.strip_nongsm_chars.encode("ISO-8859-1"),
        originator: from,
        ref: message_id,
        dlr: "true"
      }
      params[:hash] =  compute_hash(
        [sms.message.strip_nongsm_chars.encode("ISO-8859-1"), params[:originator], params[:msisdn]]
      )
      request = HTTPI::Request.new
      request.url = "#{url}?#{params.to_query}"

      begin
        HTTPI.log_level = :debug
        response = HTTPI.get request

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
        response_code = response.body.split(/\n/).first
        response_code = "0" if response_code == "200"
        # Successful response
        result = {
          message_id: message_id,
          response_code: response_code.to_s,
          response: {body: response.body},
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

    def username
      ENV["SMESS_GLOBAL_MOUTH_USER"].dup # paranoid safeguard
    end
    def password
      ENV["SMESS_GLOBAL_MOUTH_PASS"]
    end
    def sender_id
      ENV["SMESS_GLOBAL_MOUTH_SENDER_ID"]
    end

  end
end