module Smess
  class Output

    attr_accessor :sms
    attr_reader :config

    def initialize(config)
      @config = config
      validate_config
    end

    # should be used to make a reasonable validation that the configuration provided is good.
    def validate_config
      raise NoMethodError.new("You must define validate_config in your Smess output class")
    end

    # entry point to the sms delivery process.
    def deliver
      raise NoMethodError.new("You must define deliver in your Smess output class")
    end

    # entry point to the verification process.
    def verify(using: 'none')
      raise NoMethodError.new("Verify API is not supported by this Smess output")
    end
    def check(code)
      raise NoMethodError.new("Verify API is not supported by this Smess output")
    end
    
    def send_feedback(_message_sid)
      nil
    end

  end
end