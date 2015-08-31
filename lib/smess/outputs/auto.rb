module Smess
  class Auto

    def initialize(sms)
      @sms = sms
    end

    def get_output_name_for_msisdn(msisdn)
      3.downto(0).each do |index|
        return Smess.config.output_by_country_code[msisdn[0..index]] if Smess.config.output_by_country_code.key? msisdn[0..index]
      end
      Smess.config.default_output
    end

    def output_for(msisdn)
      out_class = get_output_name_for_msisdn msisdn
      "Smess::#{out_class.to_s.camelize}".constantize.new(sms)
    end

    def deliver
      out = output_for sms.to
      out.deliver
    end

    private

    attr_reader :sms

  end
end