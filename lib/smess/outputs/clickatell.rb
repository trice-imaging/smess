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
  class Clickatell
    include Smess::Logging

    def initialize
      ::Clickatell::API.debug_mode = true
      ::Clickatell::API.secure_mode = true
    end

    def split_sms(text)
      return [text] unless text.sms_length > 160
      logger.debug "message text is long"

      result = []
      while text.sms_length > 160
        logger.debug end_char = text.rindex(/[\n\r]/, 160)
        part = text[0..end_char]
        result << part
        text = text[(end_char+1)..text.length]
      end
      result << text
      result
    end

    def sender_not_supported(sms)
      sms.to[0] == "1" || # USA
      sms.to[0..2] == "962" || # Jordan
      sms.to[0..2] == "971" # UAE
    end
    def concat_not_supported(sms)
      sms.to[0] == "1" # USA
    end



    def deliver_sms(sms)
      return false unless sms.kind_of? Sms
      @sms = sms

      api = ::Clickatell::API.authenticate(
        ENV["SMESS_CLICKATELL_API_ID"],
        ENV["SMESS_CLICKATELL_USER"],
        ENV["SMESS_CLICKATELL_PASS"]
      )
      message = sms.message.strip_nongsm_chars.encode('ISO-8859-1')
      from = ENV["SMESS_CLICKATELL_SENDER_IDS"].split(",").include?(sms.originator) ? sms.originator : ENV["SMESS_CLICKATELL_SENDER_ID"]

      # Pretty pretty "feature detection"
      if sender_not_supported sms
        from = nil
      end
      if concat_not_supported sms
        message_array = split_sms(message)
      end

      begin
        if concat_not_supported sms
          response = nil
          message_array.each do |msg|
            rsp = api.send_message(sms.to, msg, {:from => from, :concat => 3, :callback => 7})
            response = rsp if response.nil?
          end
        else
          response = api.send_message(sms.to, message, {:from => from, :concat => 3, :callback => 7})
        end
      rescue Exception => e
        logger.warn response
        # connection problem or some error
        result = {
          :response_code => '-1',
          :response  => {
            :temporaryError =>'true',
            :responseCode => e.code,
            :responseText => e.message
          },
          :data => {:to => sms.to, :text => sms.message.strip_nongsm_chars, :from => from}
        }
        return result
      end
      # Successful response
      result = {
        :message_id => response['ID'],
        :response_code => '0',
        :response => response,
        :destination_address => sms.to,
        :data => {:to => sms.to, :text => sms.message.strip_nongsm_chars, :from => from}
      }
    end

  end
end
