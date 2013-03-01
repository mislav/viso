source 'https://rubygems.org'

gem 'addressable'
gem 'airbrake'
gem 'connection_pool'
gem 'em-http-request', '~> 1.0'
gem 'em-synchrony',    github: 'igrigorik/em-synchrony'
gem 'jammit-s3', :git => 'https://github.com/kmamykin/jammit-s3.git'
gem 'newrelic_rpm'
gem 'metriks'
gem 'metriks-middleware'
gem 'padrino'
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
  gem 'wrong'

  # wrong depends on ParseTree ~> 3.0 but chooses 3.0.8 over 3.0.9. Guess we're
  # back to locking dependencies.
  gem 'ParseTree', '~> 3.0.9'
end

group :development do
  gem 'compass'
  gem 'foreman'
  gem 'rake'
  gem 'rocco'
end
