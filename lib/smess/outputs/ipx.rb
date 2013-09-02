module Smess
  class Ipx
    include Smess::Logging

    def initialize
      @endpoint = account[:sms_url]

      @credentials = {
        :name => account[:username],
        :pass => account[:password]
      }
    end

    def account
      @account ||= {
        sms_url: 'http://europe.ipx.com/api/services2/SmsApi52?wsdl',
        shortcode: ENV["SMESS_IPX_SHORTCODE"],
        username: ENV["SMESS_IPX_USER"],
        password: ENV["SMESS_IPX_PASS"],
        account_name: ENV["SMESS_IPX_ACCOUNT_NAME"],
        service_name: ENV["SMESS_SERVICE_NAME"]
      }
    end

    def build_sms_payload
      # SOAP data
      @sms_options = {
        "correlationId" => Time.now.strftime('%Y%m%d%H%M%S') + @sms.to,
        "originatingAddress" => account[:shortcode],
        "originatorTON" => "0",
        "destinationAddress" => nil,
        "userData" => "",
        "userDataHeader" => "#NULL#",
        "DCS" => "-1",
        "PID" => "-1",
        "relativeValidityTime" => "-1",
        "deliveryTime" => "#NULL#",
        "statusReportFlags" => "1", # 1
        "accountName" => account[:account_name],
        "tariffClass" => "USD0",
        "VAT" => "-1",
        "referenceId" => "#NULL#",
        "serviceName" => account[:service_name],
        "serviceCategory" => "#NULL#",
        "serviceMetaData" => "#NULL#",
        "campaignName" => "#NULL#",
        "username" => account[:username],
        "password" => account[:password]
      }
    end

    def deliver_sms(sms)
      return false unless sms.kind_of? Sms

      @sms = sms
      build_sms_payload

      set_originator sms.originator
      @sms_options["destinationAddress"] = sms.to

      perform_operator_adaptation sms.to

      # validate sms contents
      parts = Smess.split_sms(sms.message.strip_nongsm_chars)
      return false if parts[0].empty?
      # if we have several parts, send them as concatenated sms
      if parts.length > 1
        logger.info "Num Parts: #{parts.length.to_s}"
        # create concat-sms smpp header
        ref_id = Random.new.rand(255).to_s(16).rjust(2,"0")
        num_parts = parts.length
        @sms_options["userDataHeader"] = "050003#{ref_id}#{num_parts.to_s(16).rjust(2,'0')}01" # {050003}{ff}{02}{01} {concat-command}{id to link all parts}{total num parts}{num of current part}
      end

      @sms_options["userData"] = parts.shift

      result = send_one_sms
      result[:data] = @sms_options.dup
      result[:data].delete "password"
      result[:data]["userData"] = sms.message.strip_nongsm_chars

      # fallback...
      unless result[:response_code].to_s == "0"
        logger.info "IPX_ERROR: #{result}"
        return fallback_to_twilio
      end

      # send aditional parts if we have them
      if parts.length > 0 && result[:response_code] != "-1"
        logger.info "Sending more parts..."
        set_originator sms.originator
        @sms_options["destinationAddress"] = sms.to

        more_results = []
        parts.each_with_index do |part,i|
          logger.info "Sending Part #{(i+2).to_s}"
          @sms_options["userData"] = part
          @sms_options["userDataHeader"] = "050003#{ref_id}#{num_parts.to_s(16).rjust(2,'0')}#{(i+2).to_s(16).rjust(2,'0')}"
          @sms_options["correlationId"] = Time.now.strftime('%Y%m%d%H%M%S') + @sms.to + (i+1).to_s
          more_results << send_one_sms
          # we don't actually return the status for any of these which is cheating
        end
      end

      result
    end

  private

    def soap_client
      Savon.configure do |config|
        config.log_level = :info
        config.raise_errors = false
      end


      endpoint = @endpoint
      mm7ns = wsdl_namespace
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

    # Delivery reliability, particularly in the US, is appalling
    # and being able to reduce non-deliveries by more than half
    # is a big deal when sending transactional messages.
    def fallback_to_twilio
      @sms.output = :twilio
      @sms.deliver
    end

    def get_response_hash_from(response)
      response.to_hash[:submit_rsp]
    end

    def get_message_id_from hash
      hash[:message_id] rescue ''
    end

    def set_originator(originator)
      @sms_options["originatingAddress"] = originator
      @sms_options["originatorTON"] = (originator.length == 5 && originator.to_i.to_s == originator) ? "0" : "1"
    end

    def xmlns
      "http://www.ipx.com/api/services/smsapi52/types"
    end

    def wsdl_namespace
      "http://www.3gpp.org/ftp/Specs/archive/23_series/23.140/schema/REL-6-MM7-1-2"
    end

    def send_one_sms
      client = soap_client
      sms_options = @sms_options
      begin
        response = client.request "SendRequest", "xmlns" => xmlns do
          soap.body = sms_options
        end
      rescue Exception => e
        result = {
          :response_code => "-1",
          :response  => {
            :temporaryError =>"true",
            :responseCode => "-1",
            :responseText => "MM: System Communication Error. #{e.inspect}"
          }
        }
        # LOG error here?
        return result
      end
      return parse_sms_response response
    end


    def parse_sms_response(response)
      # logger.debug " --- "
      # logger.debug response.to_hash
      # logger.debug " --- "
      if response.http_error? || response.soap_fault?
        result = {
          :response_code => "-1",
          :response  => {
            :temporaryError =>"true",
            :responseCode => "-1",
            :responseText => response.http_error || response.soap_fault.to_hash
          }
        }
        # LOG error here?
        return result
      end


      hash = response.to_hash[:send_response]
      message_id = ""
      message_id = hash[:message_id] if hash.has_key? :message_id
      response_code = hash[:response_code]

      result = {
        :message_id => message_id,
        :response_code => response_code,
        :response => hash
      }
    end


    # Called before final message assembly
    # used to look up the operator and make changes to the SOAP data for some carriers
    def perform_operator_adaptation(msisdn)
    end



  end
end