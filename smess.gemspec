$:.push File.expand_path("../lib", __FILE__)
require "smess/version"

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "smess"
  s.version = Smess::VERSION
  s.date = Time.now
  s.summary = "A messy SMS messenger supporting every aggregator I have gotten my hands on"
  s.description = "A mess of SMS messaging"
  s.require_paths = ["lib"]
  s.author = "Martin Westin"
  s.email = "martin@eimermusic.com"
  s.homepage = "https://github.com/eimermusic/smess"

  s.add_development_dependency 'rspec', '>= 2.4.0'
  s.add_development_dependency 'jahtml_formatter'
  s.add_development_dependency 'dotenv'
  s.add_dependency 'mail'
  s.add_dependency 'savon', '1.2.0'
  s.add_dependency 'httpi'
  s.add_dependency 'clickatell'
  s.add_dependency 'twilio-ruby'
  s.add_dependency 'activesupport', '>=3.0'

  s.files = Dir["{lib}/**/*", "[A-Z]*", "init.rb"]
  s.required_ruby_version = ">= 1.9.2"
  s.required_rubygems_version = ">= 1.3.7"
end