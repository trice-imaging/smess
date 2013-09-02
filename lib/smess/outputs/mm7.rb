module Smess

  class Mm7
    include Smess::Logging

    def initialize

      # SOAP defaults
      @endpoint = "http://example.com/mms/mm7"

      # MM7 defaults
      @mm7ns = "http://www.3gpp.org/ftp/Specs/archive/23_series/23.140/schema/REL-6-MM7-1-2"
      @mm7header = {
        "mm7:TransactionID" => Time.now.strftime('%Y%m%d%H%M%S'),
        :attributes! => {
          "mm7:TransactionID" => {
            "xmlns:mm7" => @mm7ns
          }
        }
      }
      @mm7body = {
        "mm7:MM7Version" => "6.5.0",
        "mm7:SenderIdentification" => {
          "mm7:VASPID" => "",
          "mm7:SenderAddress" => {}
        },
        "mm7:Recipients" => {
          "mm7:To" => {
            "mm7:Number" => ""
          }
        },
        "mm7:ServiceCode" => "",
        "mm7:LinkedID" => "",
        "mm7:DeliveryReport" => "true",
        "mm7:Subject" => "",
        "mm7:Content/" => nil,
        :attributes! => {"mm7:Content/" => {"href" => "cid:attachment_1"}}
      }

      @credentials = nil

    end

  private

    def perform_operator_adaptation(msisdn)
      # implement this method to do modify the message output
    end

    def soap_client
      Savon.configure do |config|
        config.log_level = :info
        config.raise_errors = false
      end


      endpoint = @endpoint
      mm7ns = @mm7ns
      credentials = @credentials

      client = Savon::Client.new do |wsdl, http|
        wsdl.endpoint = endpoint
        wsdl.namespace = mm7ns

        http.open_timeout = 15
        http.read_timeout = 60 # Won't set read timeout to 10 minutes!! (IPX are crazy)
        http.auth.basic  credentials[:name], credentials[:pass] unless credentials.nil?
      end
      client
    end

    def get_response_hash_from(response)
      response.to_hash[:submit_rsp]
    end

    def get_message_id_from hash
      hash[:message_id] rescue ''
    end

    def parse_response(response)
      logger.debug ' --- '
      logger.debug response.http_error.to_hash
      logger.debug ' --- '
      # logger.debug response.success?
      # logger.debug ' --- '
      # logger.debug "#{response.http_error}, #{response.soap_fault }"
      # logger.debug ' --- '

      unless response.success?
        result = {
          :response_code => "-1",
          :response => {
            :responseCode => "-1",
            :responseText => response.http_error? ? response.http_error.to_hash : response.soap_fault.to_hash
          }
        }

        return result
      end

      hash = get_response_hash_from response
      message_id = get_message_id_from hash

      # any 1000 range code is a success, anything else is an error.
      status_code = hash[:status][:status_code] rescue '-1'
      if (1000..1999) === status_code.to_i
        response_code = "0"
      else
        response_code = status_code
        # LOG error here?
      end

      result = {
        :message_id => message_id,
        :response_code => response_code,
        :response => hash
      }

    end

  end
end