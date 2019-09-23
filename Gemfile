source 'https://rubygems.org'

gem 'rails', '~> 5.2'

gem 'config'
gem 'devise', '~> 4.0'
gem 'devise-remote-user', '~> 1.0'
gem 'jquery-rails'
gem 'dynamic_form'
gem 'bootstrap-datepicker-rails'
gem 'carrierwave', '~> 1.0'
gem 'coderay'
gem 'validates_email_format_of'
gem 'whenever', '~> 0.9'

# Stanford stuff
gem 'assembly-objectfile', '~> 1.5'
# We don't require this by default, because we need it to load after hydrus models
# or we'll get a superclass mismatch for Hydrus::Item
gem 'dor-services', '~> 7.2', require: false
gem 'dor-services-client', '~> 2.0'
gem 'dor-workflow-client', '~> 3.9'
gem 'rubydora', '~> 2.1'
gem 'bagit', '~> 0.4'
gem 'blacklight', '~> 6.19'
gem 'cancancan', '~> 1.17'

# Use okcomputer to monitor the application
gem 'okcomputer'

gem 'bootsnap'
gem 'sassc', '~> 2.0.1' # Pinning to 2.0 because 2.1 requires GLIBC 2.14 on deploy
gem 'sass-rails',     '~> 5.0'
gem 'coffee-rails',   '~> 4.2'
gem 'uglifier', '>= 1.0.3'

# gems only needed for particular environments

group :development, :test do
  gem 'factory_bot_rails'
  gem 'sqlite3', '~> 1.3.13'
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara', '~> 2.18'
  gem 'simplecov'
  gem 'coveralls'
  gem 'equivalent-xml'
  gem 'awesome_print'
  gem 'launchy'
  gem 'byebug'
  gem 'letter_opener'
  gem 'pry'
  gem 'rubocop', '~> 0.58.1'
  # gem 'rubocop-rspec', '~> 1.5'
  gem 'rails-controller-testing'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :production do
  # Rails 4.2.10 only supports mysql2 < 0.5
  # See https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L3
  gem 'mysql2', '~> 0.4.5'
end

group :deployment do
  gem 'capistrano', '~> 3.3'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end

gem 'honeybadger'
gem 'rsolr', '~> 2.2'
