module Smess
  class Etisalatdemo
    include Smess::Logging

    attr_reader :sms

    def initialize(sms)
      @sms = sms
      @smtp_settings = {
        address:              "exmail.emirates.net.ae",
        port:                 25,
        domain:               'eim.ae',
        user_name:            ENV["SMESS_ETISALATDEMO_USER"],
        password:             ENV["SMESS_ETISALATDEMO_PASS"],
        authentication:       'plain',
        enable_starttls_auto: false
      }
    end

    def deliver
      local_from_var = from_address
      local_sms = sms
      mail = Mail.new do
        from      local_from_var
        to        "+#{local_sms.to}@email2sms.ae"
        subject   "Smess Message"
        body      local_sms.message.strip_nongsm_chars
      end

      mail.delivery_method :smtp, @smtp_settings

      begin
        mail.deliver
      rescue => e
        result = {
          response_code: "-1",
          response: {text: "Email2sms: Delivery Error: #{e.inspect}"},
          data: {
            to: sms.to,
            text: sms.message.strip_nongsm_chars,
            from: from_address
          }
        }
      else
        result = {
          response_code: "0",
          response: {text: "Email2sms: Delivery Successful"},
          data: {
            to: sms.to,
            text: sms.message.strip_nongsm_chars,
            from: from_address
          }
        }
      end
    end

    def from_address
      "#{@smtp_settings[:user_name]}@#{@smtp_settings[:domain]}"
    end

  end
end