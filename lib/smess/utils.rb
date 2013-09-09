# coding: UTF-8

module Smess
  class << self

    # returns an array of strings of gsm-compatible lengths
    # performance issue: utf8_safe_split also loops over the split point
    # this should be used when sending via concatenating providers
    def split_sms(text)
      return [text] unless text.sms_length > 160

      result = []
      while text.sms_length > 0
        end_char = 151
        part = ""
        while part.sms_length < 152 && part != text
          end_char = end_char + 1
          part = text.utf8_safe_split(end_char)[0] || ""
        end
        result << part
        text = text.utf8_safe_split(end_char)[1] || ""
      end
      result
    end

    # returns an array of strings of <160 char lengths
    # splits on whitespace and will mangle non-space whitespace
    # this should be used when sending via non-concatenating providers
    def separate_sms(text)
      return [text] unless text.sms_length > 160

      end_char = 160
      result = []
      while text.sms_length > end_char
        part = ""
        parts = text.utf8_safe_split(end_char)
        text = parts[1]
        splitpoint = end_char-parts[0].reverse.index(/[^\w-]+/)
        split = parts[0].utf8_safe_split(splitpoint)
        result << split[0].strip
        text = (split[1]+text).strip rescue text
      end
      result << text
    end


    def booleanize(value)
      value.to_s.downcase == "true"
    end


  end
end