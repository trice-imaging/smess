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
      self.results = {sent_with: output}.merge(out.deliver)
    end

    def verify(using: 'sms')
      out = Smess.named_output_instance(output)
      out.sms = self
      self.results = {sent_with: output}.merge(out.verify(using: using))
    end

    def check(code)
      out = Smess.named_output_instance(output)
      out.sms = self
      self.results = {sent_with: output}.merge(out.check(code))
    end

    def delivered?
      results[:response_code] == "0"
    end

    def send_feedback(to, message_sid)
      out = Smess.named_output_instance(output)
      @to = to
      out.sms = self
      out.send_feedback(message_sid)
    end

  end
end