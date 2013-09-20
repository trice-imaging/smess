# coding: UTF-8

module Smess
  class << self

    def booleanize(value)
      value.to_s.downcase == "true"
    end

    # returns an array of strings of gsm-compatible lengths
    # this should be used when sending via concatenating providers
    def split_sms(text)
      text = text.scan(/.{1,152}/m) if text.sms_length > SMS_MAX_LENGTH
      Array(text)
    end

    # returns an array of strings of <160 char lengths, split on whitespace
    # this should be used when sending via non-concatenating providers
    def separate_sms(text)
      return [text] unless text.sms_length > SMS_MAX_LENGTH
      result = []
      while text.sms_length > SMS_MAX_LENGTH
        part, text = text.split_at( separation_point(text) )
        result << part.strip
      end
      result << text.strip
    end

    private

    SMS_MAX_LENGTH = 160

    def separation_point(text)
      part = text.split_at(SMS_MAX_LENGTH).first
      SMS_MAX_LENGTH-part.reverse.index(/[^\w-]+/)
    end

  end
end