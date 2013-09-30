require 'uri'
require 'httpi'

module Smess
  class Mblox
    include Smess::Logging

    def initialize(sms)
      @sms = sms
      @results = []
    end

    def deliver
      xml_params = {
        subscriber_number: sms.to,
        message: ""
      }

      parts.each_with_index do |part, i|
        xml_params[:message] = part
        xml_params[:udh]  = concatenation_udh(i+1, parts.length) if parts.length > 1
        results << send_one_sms(xml_params)
      end

      results.first
    end

    def hash_data_for(xml_params)
      rand = (SecureRandom.random_number*100000000).to_i
      @message_id = rand

      xml_hash = {
        notification_request: {
          notification_header: {
            partner_name: ENV["SMESS_MBLOX_SURE_ROUTE_USER"],
            partner_password: ENV["SMESS_MBLOX_SURE_ROUTE_PASS"]
          },
          notification_list: {
            notification: {
              message: xml_params[:message],
              profile: ENV["SMESS_MBLOX_SURE_ROUTE_PROFILE_ID"],
              udh: xml_params.fetch(:udh,""),
              sender_i_d: from,
              # expire_date: "",
              # operator: "",
              # tariff: "",
              subscriber: {
                subscriber_number: xml_params[:subscriber_number],
                session_id: ""
              },
              # tags: '<Tag Name=”Number”>56</Tag><Tag Name=”City”>Paris</Tag>',
              # service_desc: "",
              # content_type: "",
              service_id: ENV["SMESS_MBLOX_SURE_ROUTE_SID"],
              attributes!: { sender_i_d: { "Type" => "Shortcode" } }
            },
            attributes!: { notification: { "SequenceNumber" => "1", "MessageType" => "SMS" } } # FlashSMS
          },
          attributes!: { notification_list: { "BatchID" => @message_id } }
        },
        attributes!: {  notification_request: { "Version" => "3.5" } }
      }
      xml_hash[:notification_request][:notification_list][:notification].delete :udh unless xml_params.key? :udh
      xml_hash
    end

    private

    attr_reader :sms
    attr_accessor :results

    def from
      ENV["SMESS_MBLOX_SURE_ROUTE_SHORTCODE"]
    end

    def parts
      @parts ||= split_parts
    end

    def split_parts
      Smess.split_sms(sms.message.strip_nongsm_chars).reject {|s| s.empty? }
    end

    def send_one_sms(xml_params)
      request.url = 'https://xml4.us.mblox.com:443/send'
      request.headers["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = http_body(xml_params)

      begin
        HTTPI.log_level = :debug
        response = HTTPI.post request
        result = normal_result(response)
      rescue => e
        logger.warn response
        # connection problem or some error
        result = result_for_error(e)
      end
      result
    end

    def http_body(xml_params)
      xml = xml_data_for(xml_params)
      "XMLDATA="+URI::encode( xml.encode("ISO-8859-1") )
    end

    def xml_data_for(xml_params)
      Gyoku.convert_symbols_to :camelcase
      '<?xml version="1.0"?>'+
      Gyoku.xml( hash_data_for(xml_params) )
    end

    def concatenation_udh(num, total)
      "050003#{ref_id}#{total.to_s(16).rjust(2,'0')}#{(num).to_s(16).rjust(2,'0')}".scan(/../).join(':').prepend(':')
    end

    def ref_id
      @ref_id ||= Random.new.rand(255).to_s(16).rjust(2,"0")
    end

    def normal_result(response)
      response_data = Nori.parse(response.body)
      response_code = response_code_for response_data
      # Successful response
      result = {
        message_id: @message_id,
        response_code: response_code,
        response: response_data,
        destination_address: sms.to,
        data: result_data
      }
    end

    def response_code_for(response_data)
      request_result_code = response_data[:notification_request_result][:notification_result_header][:request_result_code] rescue "-1"
      return "request:#{request_result_code}" unless request_result_code == "0"

      notification_result_code = response_data[:notification_request_result][:notification_result_list][:notification_result][:notification_result_code] rescue "-1"
      return "notification:#{notification_result_code}" unless notification_result_code == "0"

      subscriber_result_code = response_data[:notification_request_result][:notification_result_list][:notification_result][:subscriber_result][:subscriber_result_code] rescue "-1"
      (subscriber_result_code == "0") ? subscriber_result_code : "subscriber:#{subscriber_result_code}"
    end

    def request
      @request ||= HTTPI::Request.new
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