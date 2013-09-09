# rspec -c -f d
require 'rubygems'
require 'logger'
require 'fileutils'

require 'dotenv'
Dotenv.load ".env.test", '.env'

smess_path = File.expand_path('../lib', File.dirname(__FILE__))
$:.unshift(smess_path) if File.directory?(smess_path) && !$:.include?(smess_path)

require 'smess'

RSpec.configure do |config|
  config.mock_with :rspec
end
