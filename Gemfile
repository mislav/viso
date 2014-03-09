source 'https://rubygems.org'

# EventMachine and Ruby 2.0 don't play nicely together. Stick with 1.9.3.
#   ThreadError: Attempt to unlock a mutex which is not locked
ruby '1.9.3'

# Bundler isn't grabbing the latest versions of these gems. Help it out.
gem 'activesupport', '~> 3.2.13'
gem 'padrino',       '~> 0.11'

gem 'addressable'
gem 'airbrake'
gem 'connection_pool'
gem 'em-http-request', '~> 1.0'
gem 'em-synchrony',    github: 'igrigorik/em-synchrony'
gem 'jammit-s3', :git => 'https://github.com/kmamykin/jammit-s3.git'
gem 'metriks'
gem 'metriks-middleware'
gem 'pygments.rb'
gem 'redcarpet', '~> 2.1'
gem 'simpleidn'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'thin'
gem 'yajl-ruby'

gem 'gemoji', group: :development

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'vcr', '~> 1.11'
  gem 'webmock'
end

group :development do
  gem 'compass'
  gem 'foreman'
  gem 'rake'
  gem 'rocco'
end
