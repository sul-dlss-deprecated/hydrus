# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 4.2.9'

gem 'rake', '~> 11.0'

gem 'config'
# Devise updated for http://blog.plataformatec.com.br/2016/01/improve-remember-me-cookie-expiration-in-devise/
gem 'devise', '~> 3.5.4'
gem 'jquery-rails'
gem 'dynamic_form'
gem 'bootstrap-datepicker-rails'
gem 'cancan'
gem 'carrierwave', '~> 1.0'
gem 'coderay'
gem 'validates_email_format_of'
gem 'whenever', '~> 0.9'

# Stanford stuff
gem 'assembly-objectfile', '1.5.0'
gem 'blacklight',   '~> 4.4'
gem 'dor-services', '~> 5.24', require: false
gem 'bagit', '0.3.2' # > 0.3.2 requires ruby 2
gem 'dor-workflow-service'
gem 'net-http-persistent', '~> 2.9' # https://github.com/sul-dlss/dor-workflow-service/issues/44
gem 'druid-tools', '~> 0.4.0'
gem 'hydra-head',  '~> 6.5'

# Use okcomputer to monitor the application
gem 'okcomputer'
gem 'sul_chrome', '~> 0.1.0'

gem 'sass-rails',     '~> 4.0'
gem 'coffee-rails',   '~> 4.2'
gem 'bootstrap-sass', '2.3.2.1'
gem 'therubyracer'
gem 'libv8', '~> 3.16.14.19' # dep of therubyracer
gem 'uglifier', '>= 1.0.3'

# gems only needed for particular environments

group :development, :test do
  gem 'jettywrapper', '1.4.2'
  gem 'sqlite3'
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'simplecov'
  gem 'equivalent-xml'
  gem 'awesome_print'
  gem 'launchy'
  gem 'byebug'
  gem 'letter_opener'
# gem 'database_cleaner'
  gem 'pry'
end

group :production, :dortest do
  gem 'mysql2'
end

group :deployment do
  gem 'capistrano', '~> 3.3'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end

# Ruby 2.2+ has removed test/unit from the core library. Rails requires this as a dependency
# Rails 3.2 uses ActiveSupport::Test case in lib/rails/console/app.rb, so we need it in all groups
gem 'test-unit'

gem 'honeybadger'
gem 'rsolr-ext'
