# coding: UTF-8
smess_path = File.expand_path('.', File.dirname(__FILE__))
$:.unshift(smess_path) if File.directory?(smess_path) && !$:.include?(smess_path)

require 'mail'
require 'savon'
require 'active_support'
require 'active_support/core_ext'

require "smess/version"
require 'smess/logging'
require 'smess/output'
require 'smess/utils'
require 'smess/sms'
require 'smess/outputs/http_base'
require 'smess/outputs/auto'
require 'smess/outputs/ipx'
require 'smess/outputs/ipxus'
require 'smess/outputs/card_board_fish'
require 'smess/outputs/clickatell'
require 'smess/outputs/smsglobal'
require 'smess/outputs/global_mouth'
require 'smess/outputs/mblox'
require 'smess/outputs/twilio'
require 'smess/outputs/iconectiv'
require 'smess/outputs/test'

require 'string_ext'

module Smess

  def self.new(*args)
    Sms.new(*args)
  end

  def self.named_output_instance(name)
    output_class_name = config.configured_outputs.fetch(name)[:type].to_s.camelize
    conf = config.configured_outputs[name][:config]
    "Smess::#{output_class_name}".constantize.new(conf)
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
    attr_accessor :nothing, :default_output, :default_sender_id, :default_sender_id, :output_types, :configured_outputs, :output_by_country_code

    def initialize
      @nothing = false
      @default_output = nil
      @default_sender_id = "Smess"
      @output_types = %i{auto card_board_fish clickatell global_mouth iconectiv mblox smsglobal twilio}
      @configured_outputs = {}
      @output_by_country_code = {}

      if ENV["RAILS_ENV"] == "test"
        @configured_outputs = {test: {type: :test, config: nil}}
      end

      register_output({
        name: :auto,
        country_codes: [],
        type: :auto,
        config: {}
      })
    end

    def add_country_code(cc, output=default_output)
      raise ArgumentError.new("Invalid country code") unless cc.to_i.to_s == cc.to_s
      raise ArgumentError.new("Unknown output specified") unless outputs.include? output.to_sym
      output_by_country_code[cc.to_s] = output.to_sym
      true
    end

    def register_output(options)
      name = options.fetch(:name).to_sym
      type = options.fetch(:type).to_sym
      countries = options.fetch(:country_codes)
      config = options.fetch(:config)

      raise ArgumentError.new("Duplicate output name") if outputs.include? name
      raise ArgumentError.new("Unknown output type specified") unless output_types.include? type

      configured_outputs[name] = {type: type, config: config}
      countries.each do |cc|
        add_country_code(cc, name)
      end
    end

    def outputs
      configured_outputs.keys
    end

    def country_codes
      output_by_country_code.keys
    end

  end
end

# httpclient does not send basic auth correctly, or at all.
HTTPI.adapter = :net_http
