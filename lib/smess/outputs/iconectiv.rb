module Smess
  class Iconectiv < Ipxus

    private

    def account
      @account ||= {
        sms_url: 'http://66.70.32.42:32005/api/services2/SmsApi52?wsdl',
        shortcode: ENV["SMESS_ICONECTIV_SHORTCODE"],
        username: ENV["SMESS_ICONECTIV_USER"],
        password: ENV["SMESS_ICONECTIV_PASS"],
        account_name: ENV["SMESS_ICONECTIV_ACCOUNT_NAME"],
        service_name: ENV["SMESS_SERVICE_NAME"],
        service_meta_data_t_mobile_us: ENV["SMESS_ICONECTIV_SERVICE_META_DATA_T_MOBILE_US"],
        service_meta_data_verizon: ENV["SMESS_ICONECTIV_SERVICE_META_DATA_VERIZON"]
      }
    end

  end
end