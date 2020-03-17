require 'uri'
require 'httpi'
require 'json'

module Smess
  class LinkMobility < HttpBase

    def deliver
      request.auth.basic(username, password)
      request.url = url
      request.headers["Content-Type"] = "application/json"
      request.body = body

      http_post request
    end

    attr_accessor :username, :password, :platform_id, :platform_partner_id, :gate_id
    def validate_config
      @username  = config.fetch(:username)
      @password  = config.fetch(:password)
      @platform_id  = config.fetch(:platform_id)
      @platform_partner_id  = config.fetch(:platform_partner_id)
      @gate_id  = config.fetch(:gate_id)
      @sender_id  = config.fetch(:sender_id, @sender_id)
    end

    private

    def url
      config.fetch(:url)
    end

    def sourceTON
      if !from.nil? && from[0] == "+"
        "MSISDN"
      else
        "ALPHANUMERIC"
      end
    end

    def body
      {
        source: from,
        sourceTON: sourceTON,
        destination: "+#{sms.to}",
        userData: sms.message.strip_nongsm_chars,
        platformId: platform_id,
        platformPartnerId: platform_partner_id,
        dcs: "TEXT",
        useDeliveryReport: true,
        deliveryReportGates: [gate_id]
      }.to_json
    end

    def normal_result(response)
      response_json = JSON.parse(response.body)

      response_code = response_json["resultCode"]
      response_code = "0" if response_code == 1005

      message_id = response_json["messageId"]
      # Successful response
      {
        message_id: message_id,
        response_code: response_code.to_s,
        response: response_json,
        destination_address: sms.to,
        data: result_data
      }
    end

  end
end