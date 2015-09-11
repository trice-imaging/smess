module Smess
  class Sms

    attr_accessor :to, :message, :originator, :output, :results

    def initialize(*args)
      opts = args.first || {}
      @to = opts.fetch(:to, nil)
      @message = opts.fetch(:message, "")
      @originator = opts.fetch(:originator, nil)
      @output = opts.fetch(:output, :auto).to_sym
    end

    def deliver
      out = Smess.named_output_instance(output)
      out.sms = self
      results = out.deliver
    end

    def delivered?
      results[:response_code] == "0"
    end

  end
end