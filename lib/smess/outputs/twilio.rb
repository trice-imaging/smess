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

    def deliver
      send_one_sms sms.message.strip_nongsm_chars
    end

    private

    attr_accessor :results

    def parts
      @parts ||= split_parts
    end

    def split_parts
      Smess.separate_sms(sms.message.strip_nongsm_chars).reject {|s| s.empty? }
    end

    def send_one_sms(message)
      begin
        opts = {
          to: "+#{sms.to}",
          body: message,
          status_callback: callback_url
        }
        if messaging_service_sid.present?
          opts[:messaging_service_sid] =  messaging_service_sid
        else
          opts[:from] =  from
        end
        response = create_client_message(opts)
        result = normal_result(response)
      rescue => e
        result = result_for_error(e)
      end
      result
    end

    def create_client_message(params)
      client.account.messages.create(params)
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
        response: MultiJson.load(client.last_response.body),
        destination_address: sms.to,
        data: result_data
      }
    end

    def result_for_error(e)
      {
        response_code: '-1',
        response: {
          temporaryError: 'true',
          responseCode: '-1',
          responseText: e.message
        },
        data: result_data
      }
    end

    def result_data
      {
        to: sms.to,
        text: sms.message.strip_nongsm_chars,
        from: from
      }
    end

  end
end