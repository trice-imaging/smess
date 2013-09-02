module Smess
  module Logging

    def logger
      # use the Rails logger if it's defined
      @logger ||= if defined?(Rails)
        Rails.logger
      else
        l = ::Logger.new(STDOUT)
        l.level = Logger::WARN
        l
      end
    end

  end
end