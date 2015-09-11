require 'uri'
require 'httpi'

module Smess
  class GlobalMouth < HttpBase

    def deliver
      generate_mac_hash
      request.url = "#{url}?#{params.to_query}"
      http_get request
    end

    attr_accessor :username, :password, :sender_id
    def validate_config
      @username  = config.fetch(:username)
      @password  = config.fetch(:password)
      @sender_id = config.fetch(:sender_id)
    end

    private

    def username
      @username.dup # paranoid safeguard
    end

    def url
      "https://mcm.globalmouth.com:8443/api/mcm"
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

  end
end