# coding: UTF-8

module Smess
  class << self

    def booleanize(value)
      value.to_s.downcase == "true"
    end

    # returns an array of strings of gsm-compatible lengths
    # this should be used when sending via concatenating providers
    def split_sms(text)
      return [text] unless text.sms_length > 160
      result = []

      while text.sms_length > 0
        part, text = text.split_at( split_point(text) )
        result << part
      end
      result
    end

    # it is not as simple as
    #def split_sms(text)
    #  text = text.scan(/.{1,154}/m) if text.sms_length > SMS_MAX_LENGTH
    #  Array(text)
    #end
    # (which i forgot trying to please Code Climate)



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

    # for finding the GSM alphabet split point for concatenated message strings
    # The reason this is a bit qirky is that a subset of characters are "extended".
    # These and take 2 bytes and the number of these in the message body alter the
    # "byte" splitpoint.
    def split_point(text)
      end_char = 155
      while text.sms_length > 154
        end_char -= 1
        text = text.split_at(end_char).first
        # puts "split_point #{end_char}"
      end
      end_char
    end

    # This is used when there is no concatenation and you want the string split on whitespace.
    def separation_point(text)
      end_char = SMS_MAX_LENGTH + 1
      while text.sms_length > SMS_MAX_LENGTH || !(text[-1] =~ /\s/)
        end_char -= 1
        text = text.split_at(end_char).first
      end
      end_char
    end

  end
end