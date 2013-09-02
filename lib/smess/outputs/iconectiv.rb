module Smess
  class Iconectiv < Ipxus

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

    def account
      @account ||= {
        sms_url: 'http://66.70.32.42:32005/api/services2/SmsApi52?wsdl',
        shortcode: ENV["SMESS_ICONECTIV_SHORTCODE"],
        username: ENV["SMESS_ICONECTIV_USER"],
        password: ENV["SMESS_ICONECTIV_PASS"],
        account_name: ENV["SMESS_ICONECTIV_ACCOUNT_NAME"],
        service_name: ENV["SMESS_SERVICE_NAME"],
        service_meta_data_t_mobile: ENV["SMESS_ICONECTIV_SERVICE_META_DATA_T_MOBILE_US"],
        service_meta_data_verizon: ENV["SMESS_ICONECTIV_SERVICE_META_DATA_VERIZON"]
      }
    end

    def fallback_to_twilio
    end

  end
end