require 'twilio-ruby'

module Smess
  class Twilio < Output
    include Smess::Logging

    def initialize(config)
      super
      @results = []
    end

    attr_accessor :sid, :auth_token, :from, :messaging_service_sid, :callback_url

    def validate_config
      @sid = config.fetch(:sid)
      @auth_token = config.fetch(:auth_token)
      @from = config.fetch(:from, nil)
      @messaging_service_sid = config.fetch(:messaging_service_sid, nil)
      @callback_url = config.fetch(:callback_url)
    end

    def send_feedback(message_sid)
      client.messages(message_sid).feedback.create(outcome: "confirmed")
    end

    def deliver
      send_one_sms sms.message
    end

    private

    attr_accessor :results

    def parts
      @parts ||= split_parts
    end

    def split_parts
      Smess.separate_sms(sms.message).reject { |s| s.empty? }
    end

    def to
      "+#{sms.to}"
    end

    def sender
      if messaging_service_sid.present?
        {messaging_service_sid: messaging_service_sid}
      else
        {from: from}
      end
    end

    def send_one_sms(message)
      begin
        opts = {
          to: to,
          body: message,
          status_callback: callback_url,
          provide_feedback: true
        }
        opts.merge!(sender)
        response = create_client_message(opts)
        result = normal_result(response)
      rescue => e
        puts "got exception #{e.inspect}"
        result = result_for_error(e)
      end
      result
    end

    def create_client_message(params)
      client.api.account.messages.create(params)
    end

    def client
      @client ||= ::Twilio::REST::Client.new(sid, auth_token)
    end

    def normal_result(response)
      response_code = response.status
      response_code = "0" unless response.status == "failed"
      # Successful response
      {
        message_id: response.sid,
        response_code: response_code.to_s,
        response: {
          sid: response.sid,
          status: response.status,
          error_code: response.error_code,
          error_message: response.error_message
        },
        destination_address: sms.to,
        data: result_data
      }
    end

    def result_for_error(e)
      code = "-1"
      code = e.code.to_s rescue code
      {
        response_code: code,
        response: {
          temporaryError: 'true',
          responseCode: code,
          responseText: e.message
        },
        data: result_data
      }
    end

    def result_data
      {
        to: sms.to,
        text: sms.message,
        from: from
      }
    end

  end
end