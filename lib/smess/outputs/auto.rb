module Smess
  class Auto

    def get_output_name_for_msisdn(msisdn)
      3.downto(0).each do |index|
        return OUTPUT_BY_COUNTRY_CODE[msisdn[0..index]] if OUTPUT_BY_COUNTRY_CODE.key? msisdn[0..index]
      end
      OUTPUT_BY_COUNTRY_CODE["0"]
    end

    def output_for(msisdn)
      out_class = get_output_name_for_msisdn msisdn
      ("Smess::#{out_class.to_s.camelize}").constantize.new
    end

    def deliver_sms(sms)
      out = output_for sms.to
      if out.respond_to? :deliver_sms
        out.deliver_sms sms
      else
        nil
      end
    end

  end
end