# coding: UTF-8
smess_path = File.expand_path('.', File.dirname(__FILE__))
$:.unshift(smess_path) if File.directory?(smess_path) && !$:.include?(smess_path)

require 'mail'
require 'savon'
require 'active_support'
require 'active_support/core_ext'

require "smess/version"
require 'smess/logging'
require 'smess/utils'
require 'smess/sms'
require 'smess/outputs/http_base'
require 'smess/outputs/auto'
require 'smess/outputs/ipx'
require 'smess/outputs/ipxus'
require 'smess/outputs/card_board_fish'
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
  class << self
    attr_writer :config
  end

  # Move to config?
  OUTPUTS = %w{auto card_board_fish clickatell etisalatdemo global_mouth iconectiv mblox smsglobal twilio}
  COUNTRY_CODES = [1, 20, 212, 33, 34, 44, 46, 49, 594, 966, 971]

  def self.new(*args)
    Sms.new(*args)
  end

  def self.config
    @config ||= Config.new
  end

  def self.reset_config
    @config = Config.new
  end

  def self.configure
    yield(config)
  end

  class Config
    attr_accessor :debug, :default_output, :country_codes, :output_by_country_code

    def initialize
      @debug = false
      @default_output = :global_mouth
      @country_codes = [1, 20, 212, 33, 34, 44, 46, 49, 594, 966, 971]
      @output_by_country_code = {
        "1"   => :iconectiv,        # USA
        "1242"=> :global_mouth,     # Bahamas
        "1246"=> :global_mouth,     # Barbados
        "1264"=> :global_mouth,     # Anguilla
        "1268"=> :global_mouth,     # Antigua and Barbuda
        "1284"=> :global_mouth,     # British Virgin Islands
        "1345"=> :global_mouth,     # Cayman Islands
        "1441"=> :clickatell,       # Bermuda
        "1473"=> :global_mouth,     # Grenada
        "1649"=> :global_mouth,     # Turks and Caicos Islands
        "1664"=> :global_mouth,     # Montserrat
        "1670"=> :global_mouth,     # Northern Mariana Islands
        "1671"=> :global_mouth,     # Guam
        "1684"=> :global_mouth,     # American Samoa
        "1758"=> :global_mouth,     # Saint Lucia
        "1767"=> :global_mouth,     # Dominica
        "1784"=> :global_mouth,     # Saint Vincent and the Grenadines
        "1787"=> :global_mouth,     # Puerto Rico
        "1809"=> :global_mouth,     # Dominican Republic
        "1868"=> :global_mouth,     # Trinidad and Tobago
        "1869"=> :global_mouth,     # Saint Kitts and Nevis
        "1876"=> :global_mouth,     # Jamaica
        "20"  => :global_mouth,     # Egypt
        "212" => :card_board_fish,  # Morocco
        "33"  => :global_mouth,     # France
        "34"  => :global_mouth,     # Spain
        "44"  => :global_mouth,     # Great Britain
        "46"  => :global_mouth,     # Sweden
        "49"  => :global_mouth,     # Germany
        "594" => :global_mouth,     # French Guiana
        "966" => :global_mouth,     # Saudi Arabia
        "971" => :etisalatdemo      # United Arab Emirates
      }
    end

  end

end

# httpclient does not send basic auth correctly, or at all.
HTTPI.adapter = :net_http
