require 'twilio-ruby'

module Smess
  class Twilio < Output
    include Smess::Logging

    def initialize(config)
      super
      @results = []
    end

    attr_accessor :sid, :auth_token, :api_key, :api_secret, :from, :messaging_service_sid, :callback_url, :verify_service_sid

    def validate_config
      @sid = config.fetch(:sid)
      @auth_token = config.fetch(:auth_token, nil)
      @api_key = config.fetch(:api_key, nil)
      @api_secret = config.fetch(:api_secret, nil)
      raise "missing API credentials" unless auth_token.present? || (api_key.present? && api_secret.present?)
      @from = config.fetch(:from, nil)
      @messaging_service_sid = config.fetch(:messaging_service_sid, nil)
      @callback_url = config.fetch(:callback_url)
      @verify_service_sid = config.fetch(:verify_service_sid, nil)
    end

    def send_feedback(message_sid)
      client.messages(message_sid).feedback.create(outcome: "confirmed")
    end

    def deliver
      send_one_sms sms.message
    end

    def verify(using: 'sms')
      response = client.verify.v2
        .services(verify_service_sid)
        .verifications
        .create(to: to, channel: using)
      {
        'sid' => response.sid,
        'service_sid' => response.service_sid,
        'account_sid' => response.account_sid,
        'to' => response.to,
        'channel' => response.channel,
        'status' => response.status,
        'valid' => response.valid,
        'lookup' => response.lookup,
        'amount' => response.amount,
        'payee' => response.payee,
        'send_code_attempts' => response.send_code_attempts,
        'date_created' => response.date_created,
        'date_updated' => response.date_updated,
        'sna' => response.sna,
        'url' => response.url
      }  
    end

    def check(code)
      response = client.verify.v2
        .services(verify_service_sid)
        .verification_checks
        .create(to: to, code: code)
      {
        'sid' => response.sid,
        'service_sid' => response.service_sid,
        'account_sid' => response.account_sid,
        'to' => response.to,
        'channel' => response.channel,
        'status' => response.status,
        'valid' => response.valid,
        'amount' => response.amount,
        'payee' => response.payee,
        'date_created' => response.date_created,
        'date_updated' => response.date_updated,
        'sna_attempts_error_codes' => response.sna_attempts_error_codes,
      }
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
      rescue ::Twilio::REST::RestError => e
        puts "got exception #{e.inspect}"
        result = result_for_error(e)
      end
      result
    end

    def create_client_message(params)
      client.api.account.messages.create(**params)
    end

    def client
      @client ||= auth_token.present? ? ::Twilio::REST::Client.new(sid, auth_token) : ::Twilio::REST::Client.new(api_key, api_secret, sid)
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
        data: result_data.merge({
          price: response.price,
          price_unit: response.price_unit,
          num_segments: response.num_segments
        })
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
