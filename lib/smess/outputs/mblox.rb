require 'uri'
require 'httpi'

module Smess
  class Mblox
    include Smess::Logging

    def deliver_sms(sms)
      return false unless sms.kind_of? Sms

      parts = Smess.split_sms(sms.message.strip_nongsm_chars)
      return false if parts[0].empty?

      xml_params = {
        subscriber_number: sms.to,
        message: ""
      }
      # if we have several parts, send them as concatenated sms
      if parts.length > 1
        logger.info "Num Parts: #{parts.length.to_s}"
        # create concat-sms UDH
        ref_id = Random.new.rand(255).to_s(16).rjust(2,"0")
        num_parts = parts.length
        xml_params[:udh] = ":05:00:03:#{ref_id}:#{num_parts.to_s(16).rjust(2,'0')}:01" # {050003}{ff}{02}{01} {concat-command}{id to link all parts}{total num parts}{num of current part}
      end

      xml_params[:message] = parts.shift
      # send first SMS... the one we return the result from...
      result = send_one_sms( xml_params )
      result[:data][:text] = sms.message.strip_nongsm_chars


      # send additional parts if we have them
      if parts.length > 0 && result[:response_code] != "-1"
        more_results = []
        parts.each_with_index do |part, i|
          xml_params[:message] = part
          xml_params[:udh]  = ":05:00:03:#{ref_id}:#{num_parts.to_s(16).rjust(2,'0')}:#{(i+2).to_s(16).rjust(2,'0')}"
          more_results << send_one_sms( xml_params )
        end
        # we don't actually return the status for any of these which is cheating
        logger.info more_results
      end

      result
    end


    def send_one_sms(xml_params)
      xml = xml_data_for(xml_params)
      body = "XMLDATA="+URI::encode( xml.encode("ISO-8859-1") ) # escape

      request = HTTPI::Request.new
      request.url = 'https://xml4.us.mblox.com:443/send'
      request.headers["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = body

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
            to: xml_params[:subscriber_number],
            text: xml_params[:message],
            from: ENV["SMESS_MBLOX_SURE_ROUTE_SHORTCODE"]
          }
        }
      else
        response_data = Nori.parse(response.body)
        response_code = response_code_for response_data
        # Successful response
        result = {
          message_id: @message_id,
          response_code: response_code,
          response: response_data,
          destination_address: xml_params[:subscriber_number],
          data: {
            to: xml_params[:subscriber_number],
            text: xml_params[:message],
            from: ENV["SMESS_MBLOX_SURE_ROUTE_SHORTCODE"]
          }
        }
      end
      result
    end


    def xml_data_for(xml_params)
      Gyoku.convert_symbols_to :camelcase
      '<?xml version="1.0"?>'+
      Gyoku.xml( hash_data_for(xml_params) )
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
              sender_i_d: ENV["SMESS_MBLOX_SURE_ROUTE_SHORTCODE"],
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

    def response_code_for(response_data)
      request_result_code = response_data[:notification_request_result][:notification_result_header][:request_result_code] rescue "-1"
      return "request:#{request_result_code}" unless request_result_code == "0"

      notification_result_code = response_data[:notification_request_result][:notification_result_list][:notification_result][:notification_result_code] rescue "-1"
      return "notification:#{notification_result_code}" unless notification_result_code == "0"

      subscriber_result_code = response_data[:notification_request_result][:notification_result_list][:notification_result][:subscriber_result][:subscriber_result_code] rescue "-1"
      (subscriber_result_code == "0") ? subscriber_result_code : "subscriber:#{subscriber_result_code}"
    end

  end
end