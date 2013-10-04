module Smess
  class Sms

    attr_accessor :to, :message, :originator, :output, :results

    def initialize(*args)
      opts = args.first || {}
      @to = opts.fetch(:to, nil)
      @message = opts.fetch(:message, "")
      @originator = opts.fetch(:originator, nil)
      @output = opts.fetch(:output, "auto")
    end

    def deliver
      out_class = output
      out = ("Smess::#{out_class.to_s.camelize}").constantize.new(self)
      results = out.deliver
    end

    def delivered?
      results[:response_code] == "0"
    end

  end
end