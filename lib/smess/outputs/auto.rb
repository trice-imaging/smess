module Smess
  class Auto

    def initialize(sms)
      @sms = sms
    end

    def get_output_name_for_msisdn(msisdn)
      3.downto(0).each do |index|
        return OUTPUT_BY_COUNTRY_CODE[msisdn[0..index]] if OUTPUT_BY_COUNTRY_CODE.key? msisdn[0..index]
      end
      OUTPUT_BY_COUNTRY_CODE["0"]
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