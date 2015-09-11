module Smess
  class Auto < Output

    def validate_config
    end

    def deliver
      out = output_for sms.to
      out.deliver
    end

    def get_output_name_for_msisdn(msisdn)
      3.downto(0).each do |index|
        return Smess.config.output_by_country_code[msisdn[0..index]] if Smess.config.output_by_country_code.key? msisdn[0..index]
      end
      Smess.config.default_output
    end

    def output_for(msisdn)
      output = Smess.named_output_instance( get_output_name_for_msisdn(msisdn) )
      output.sms = sms
      output
    end

  end
end