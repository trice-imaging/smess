module Smess
  class Ipx
    include Smess::Logging

    def initialize(sms)
      @sms = sms
      @results = []
      @endpoint = account[:sms_url]
      @credentials = {
        name: account[:username],
        pass: account[:password]
      }
    end

    def deliver
      set_originator(sms.originator)
      perform_operator_adaptation(sms.to)

      parts.each_with_index do |part, i|
        populate_soap_body(part, i)
        results << send_one_sms

        # halt and use fallback on error...
        if last_result_was_error
          logger.info "IPX_ERROR: #{results.last}"
          return fallback_to_twilio || results.first
        end
      end

      # we don't actually return the status for any of additional messages which is cheating
      results.first
    end

    private

    attr_reader :sms
    attr_accessor :results

    def account_key_prefix
      "IPX"
    end

    def account_key_for(key_part)
      "SMESS_#{account_key_prefix}_#{key_part}"
    end

    def account
      @account ||= {
        sms_url: ENV[ account_key_for("URL") ],
        shortcode: ENV[ account_key_for("SHORTCODE") ],
        username: ENV[ account_key_for("USER") ],
        password: ENV[ account_key_for("PASS") ],
        account_name: ENV[ account_key_for("ACCOUNT_NAME") ],
        service_name: ENV["SMESS_SERVICE_NAME"],
        service_meta_data_t_mobile_us: ENV[ account_key_for("SERVICE_META_DATA_T_MOBILE_US") ] ,
        service_meta_data_verizon: ENV[ account_key_for("SERVICE_META_DATA_VERIZON") ]
      }
    end

    def soap_body
      @soap_body ||= {
        "correlationId" => Time.now.strftime('%Y%m%d%H%M%S') + sms.to,
        "originatingAddress" => account[:shortcode],
        "originatorTON" => "0",
        "destinationAddress" => sms.to,
        "userData" => "",
        "userDataHeader" => "#NULL#",
        "DCS" => "-1",
        "PID" => "-1",
        "relativeValidityTime" => "-1",
        "deliveryTime" => "#NULL#",
        "statusReportFlags" => "1", # 1
        "accountName" => account[:account_name],
        "tariffClass" => "USD0", # needs to be extracted and variable per country
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
      sms.output = :twilio
      sms.deliver
    end

    def get_response_hash_from(response)
      response.to_hash[:submit_rsp]
    end

    def get_message_id_from hash
      hash[:message_id] rescue ''
    end

    def set_originator(originator)
      soap_body["originatingAddress"] = originator
      soap_body["originatorTON"] = (originator.length == 5 && originator.to_i.to_s == originator) ? "0" : "1"
    end

    def xmlns
      "http://www.ipx.com/api/services/smsapi52/types"
    end

    def wsdl_namespace
      "http://www.3gpp.org/ftp/Specs/archive/23_series/23.140/schema/REL-6-MM7-1-2"
    end

    def parts
      @parts ||= split_parts
    end

    def split_parts
      Smess.split_sms(sms.message.strip_nongsm_chars).reject {|s| s.empty? }
    end

    # {050003}{ff}{02}{01} {concat-command}{id to link all parts}{total num parts}{num of current part}
    def concatenation_udh(num, total)
      "050003#{ref_id}#{total.to_s(16).rjust(2,'0')}#{(num).to_s(16).rjust(2,'0')}"
    end

    def ref_id
      @ref_id ||= Random.new.rand(255).to_s(16).rjust(2,"0")
    end

    def populate_soap_body(part, i)
      # if we have several parts, send them as concatenated sms using UDH codes
      soap_body["userDataHeader"] = concatenation_udh(i+1, parts.length) if parts.length > 1
      soap_body["userData"] = part
      soap_body["correlationId"] = Time.now.strftime('%Y%m%d%H%M%S') + sms.to + (i+1).to_s
    end

    def send_one_sms
      client = soap_client
      soap_body_var = soap_body
      begin
        response = client.request "SendRequest", "xmlns" => xmlns do
          soap.body = soap_body_var
        end
        result = parse_sms_response(response)
      rescue Exception => e
        result = result_for_error(e)
        # LOG error here?
      end
      result
    end

    def last_result_was_error
      results.last.fetch(:response_code, '').to_s != "0"
    end

    def parse_sms_response(response)
      if response.http_error? || response.soap_fault?
        e = Struct.new(:code, :message).new("-1", response.http_error || response.soap_fault.to_hash)
        result = result_for_error(e)
      else
        result = normal_result(response)
      end
      result
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

    def normal_result(response)
      hash = response.to_hash[:send_response]
      message_id = ""
      message_id = hash[:message_id] if hash.has_key? :message_id
      response_code = hash[:response_code]

      {
        message_id: message_id,
        response_code: response_code,
        response: hash,
        destination_address: sms.to,
        data: result_data
      }
    end

    def result_data
      data = soap_body.dup
      data.delete "password"
      data["userData"] = sms.message.strip_nongsm_chars
      data
    end


    # Called before final message assembly
    # used to look up the operator and make changes to the SOAP data for some carriers
    def perform_operator_adaptation(msisdn)
    end



  end
end