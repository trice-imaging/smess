# coding: UTF-8
require 'rubygems'

require 'dotenv'
Dotenv.load ".env.development", '.env'

smess_path = File.expand_path('../', File.dirname(__FILE__))
$:.unshift(smess_path) if File.directory?(smess_path) && !$:.include?(smess_path)
require smess_path+'/lib/smess'


phone_to_send_to = "..."

@sms = Smess::Sms.new(
  to: phone_to_send_to,
  message: "Smess Test. 3 funky characters: åäö might work."
)
