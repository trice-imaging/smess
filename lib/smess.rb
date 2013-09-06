# encoding: UTF-8
smess_path = File.expand_path('.', File.dirname(__FILE__))
$:.unshift(smess_path) if File.directory?(smess_path) && !$:.include?(smess_path)

require 'mail'
require 'savon'
require 'active_support/core_ext'

require "smess/version"
require 'smess/logging'
require 'smess/country_code_registry'
require 'smess/utils'
require 'smess/sms'
require 'smess/outputs/http_base'
require 'smess/outputs/auto'
require 'smess/outputs/ipx'
require 'smess/outputs/ipxus'
require 'smess/outputs/clickatell'
require 'smess/outputs/etisalatdemo'
require 'smess/outputs/smsglobal'
require 'smess/outputs/global_mouth'
require 'smess/outputs/mblox'
require 'smess/outputs/twilio'
require 'smess/outputs/iconectiv'
require 'smess/outputs/test'

require 'string'

module Smess

  # Move to config?
  OUTPUTS = %w{auto clickatell etisalatdemo global_mouth iconectiv mblox ipxus smsglobal twilio}
  COUNTRY_CODES = [1, 20, 34, 46, 49, 966, 971]

  def self.new(*args)
    Sms.new(*args)
  end

  def self.config
    @config ||=Config.new
  end

  class Config
    def initialize
      @config=Hash.new
    end
    def method_missing(method,*args,&block)
      method = method.to_s.gsub(/[=]/,'')
      if args.length>0
        @config[method] = args.first
      end
      @config[method]
    end
  end

end

# httpclient does not send basic auth correctly, or at all.
HTTPI.adapter = :net_http

# Setting config defaults
# there is probably a better way and better place
Smess.config.debug = Smess.booleanize(ENV["SMESS_DEBUG"])
