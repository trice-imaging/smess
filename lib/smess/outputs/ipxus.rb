module Smess
  class Ipxus < Ipx

    def account
      @account ||= {
        sms_url: 'http://europe.ipx.com/api/services2/SmsApi52?wsdl',
        shortcode: ENV["SMESS_IPX_SHORTCODE"],
        username: ENV["SMESS_IPX_USER"],
        password: ENV["SMESS_IPX_PASS"],
        account_name: ENV["SMESS_IPX_ACCOUNT_NAME"],
        service_name: ENV["SMESS_SERVICE_NAME"],
        service_meta_data_t_mobile_us: ENV["SMESS_IPX_SERVICE_META_DATA_T_MOBILE_US"],
        service_meta_data_verizon: ENV["SMESS_IPX_SERVICE_META_DATA_VERIZON"]
      }
    end

  private

    def set_originator(originator)
      # Cannot set custom originator in the US
    end

    # Called before final message assembly
    # used to look up the operator and make changes to the MM7 for Verizon and T-mobile
    def perform_operator_adaptation(msisdn)
      if @mms && @mms.slides.empty?
        @mm7body["mm7:ServiceCode"] << ";contentMetaData=devicediscovery=true"
        return false
      else
        operator_data = lookup_operator msisdn
        unless operator_data[:operator].nil?
          method_name = "adapt_for_#{operator_data[:operator].to_underscore.gsub(" ","_")}"
          send(method_name,msisdn) if respond_to?(:"#{method_name}", true)
        end
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
        "username" => account[:username],
        "password" => account[:password]
      }

      begin
        response = client.request "ResolveOperatorRequest", "xmlns"=>"http://www.ipx.com/api/services/consumerlookupapi09/types" do
          soap.body = body
        end
      rescue Exception => e
        result = {
          :response_code => "-1",
          :response  => {
            :temporaryError =>"true",
            :responseCode => "-1",
            :responseText => "MM: System Communication Error"
          }
        }
        # LOG error here?
        @endpoint = orig_endpoint
        @credentials = orig_credentials
        return result
      end
      @endpoint = orig_endpoint
      @credentials = orig_credentials
      return parse_operator_response response
    end

    def parse_operator_response(response)
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

      hash = response.to_hash[:resolve_operator_response]
    end


    def adapt_for_verizon(msisdn)
      @sms_options["serviceMetaData"] = account[:service_meta_data_verizon]
    end

    def adapt_for_t_mobile_us(msisdn)
      @sms_options["serviceMetaData"] = account[:service_meta_data_t_mobile_us]
    end

  end
end