module Smess
  class Test < Output

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

    def initialize(config)
      super
      @@instance = self
    end

    def self.instance
      @@instance
    end

    def validate_config
    end

    def deliver
      self.class.delivery_result
    end

  end
end
