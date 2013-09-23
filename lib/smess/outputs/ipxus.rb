module Smess
  class Ipxus < Ipx

  private

    def set_originator(originator)
      # Cannot set custom originator in the US
    end

    # Called before final message assembly
    # used to look up the operator and make changes to the MM7 for Verizon and T-mobile
    def perform_operator_adaptation(msisdn)
      operator_data = lookup_operator msisdn
      unless operator_data[:operator].nil?
        method_name = "adapt_for_#{operator_data[:operator].to_underscore.gsub(" ","_")}"
        send(method_name, msisdn) if respond_to?(:"#{method_name}", true)
      end
    end

    def lookup_operator(msisdn)
      orig_endpoint = @endpoint
      orig_credentials = @credentials
      @endpoint = "http://europe.ipx.com/api/services/ConsumerLookupApi09"
      @credentials = nil
      client = soap_client
      client.wsdl.namespace = "http://www.ipx.com/api/services/consumerlookupapi09/types"
      body = {
        "correlationId" => Time.now.strftime('%Y%m%d%H%M%S') + msisdn,
        "consumerId" => msisdn,
        "campaignName" => "#NULL#",
        "username" => username,
        "password" => password
      }

      begin
        response = client.request "ResolveOperatorRequest", "xmlns"=>"http://www.ipx.com/api/services/consumerlookupapi09/types" do
          soap.body = body
        end
        result = parse_operator_response(response)
      rescue Exception => e
        result = result_for_error(e)
      ensure
        @endpoint = orig_endpoint
        @credentials = orig_credentials
      end
      result
    end

    def parse_operator_response(response)
      if response.http_error? || response.soap_fault?
        e = Struct.new(:code, :message).new("-1", response.http_error || response.soap_fault.to_hash)
        result = result_for_error(e)
      else
        result = response.to_hash[:resolve_operator_response]
      end
      result
    end


    def adapt_for_verizon(msisdn)
      soap_body["serviceMetaData"] = service_meta_data_verizon
    end

    def adapt_for_t_mobile_us(msisdn)
      soap_body["serviceMetaData"] = service_meta_data_t_mobile_us
    end

  end
end