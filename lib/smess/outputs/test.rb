module Smess
  class Test

    @@instance = nil
    @delivery_result = {
      :response_code => '-1',
      :response  => {
        :temporaryError =>'true',
        :responseCode => '-1',
        :responseText => 'No delivery result set in test output object.'
      }
    }
    class << self; attr_accessor :delivery_result end
    attr_reader :sms, :mms

    def initialize
      @@instance = self
    end

    def self.instance
      @@instance
    end

    def deliver_sms(sms)
      return false unless sms.kind_of? Sms
      @sms = sms
      self.class.delivery_result
    end

  end
end
