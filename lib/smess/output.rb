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
      raise NotImplementedError.new("You must define validate_config in your Smess output class")
    end

    # entry point to the sms delivery process.
    def deliver
      raise NotImplementedError.new("You must define deliver in your Smess output class")
    end

  end
end