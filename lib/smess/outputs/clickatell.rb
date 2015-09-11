require 'clickatell'

# This hack should be removed soon
module Clickatell
  class API

    def send_message(recipient, message_text, opts={})
      valid_options = opts.only(:from, :mo, :callback, :climsgid, :concat)
      valid_options.merge!(:req_feat => '48') if valid_options[:from]
      valid_options.merge!(:mo => '1') if opts[:set_mobile_originated]
      valid_options.merge!(:climsgid => opts[:client_message_id]) if opts[:client_message_id]
      valid_options[:deliv_ack] = 1 if opts[:callback]
      recipient = recipient.join(",")if recipient.is_a?(Array)
      response = execute_command('sendmsg', 'http',
        {:to => recipient, :text => message_text}.merge(valid_options)
      )
      response = parse_response(response)
      #response.is_a?(Array) ? response.map { |r| r['ID'] } : response['ID']
    end

  end
end


module Smess
  class Clickatell < Output
    include Smess::Logging

    def initialize(config)
      super
      ::Clickatell::API.debug_mode = true
      ::Clickatell::API.secure_mode = true
    end

    def deliver
      begin
        responses = []
        messages.each do |msg|
          rsp = api.send_message(sms.to, msg.encode('ISO-8859-1'), {from: from, concat: 3, callback: 7})
          responses << rsp
        end
        result = normal_result(responses.first)
      rescue => e
        # connection problem or some error
        result = result_for_error(e)
      end
      result
    end

    attr_accessor :api_id, :user, :pass, :sender_id, :sender_ids
    def validate_config
      @api_id     = config.fetch(:api_id)
      @user       = config.fetch(:user)
      @pass       = config.fetch(:pass)
      @sender_id  = config.fetch(:sender_id)
      @sender_ids = config.fetch(:sender_ids)
    end

    private

    attr_reader :sms

    def from
      return nil if sender_not_supported
      sender_ids.split(",").include?(sms.originator) ? sms.originator : sender_id
    end

    def messages
      msg = sms.message.strip_nongsm_chars
      concat_not_supported ? Smess.separate_sms(msg) : [msg]
    end

    # "feature detection"
    # Clickatell's API requires knowledge of country-specific quirks and feature support.
    # Supported features can and does change without notice, breaking some countries.
    def sender_not_supported
      sms.to[0] == "1" || # USA
      sms.to[0..2] == "962" || # Jordan
      sms.to[0..2] == "971" # UAE
    end
    def concat_not_supported
      sms.to[0] == "1" # USA
    end

    def api
      @api ||= ::Clickatell::API.authenticate(api_id, user, pass)
    end

    def normal_result(response)
      # Successful response
      {
        message_id: response['ID'],
        response_code: '0',
        response: response,
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
