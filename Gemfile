source 'https://rubygems.org'

gem 'rails', '3.2.22.5'

# Rails 3.2 isn't ready for rake 12.
# Raises: NoMethodError: undefined method `last_comment' for #<Rake::Application:0x007f8ce8826000>
gem 'rake', '~> 11.0'

# Devise updated for http://blog.plataformatec.com.br/2016/01/improve-remember-me-cookie-expiration-in-devise/
gem 'devise', '~> 3.5.4'
gem 'rails-secrets' # Needed until we upgrade to Rails 4.1+
gem 'jquery-rails'
gem 'dynamic_form'
gem 'bootstrap-datepicker-rails'
gem 'cancan'
gem 'carrierwave', '0.6.2'
gem 'coderay'
gem 'validates_email_format_of'
gem 'whenever', '~> 0.9'

# Stanford stuff
gem 'about_page'
gem 'active-fedora', '~> 5.7.1'
gem 'assembly-objectfile', '1.5.0'
gem 'blacklight',   '~> 4.4'
gem 'dor-services', '~> 4.21'
gem 'bagit', '0.3.2' # > 0.3.2 requires ruby 2
gem 'dor-workflow-service'
gem 'druid-tools', '~> 0.4.0'
gem 'hydra-head',  '~> 5.1', '>= 5.4.1'
# Use okcomputer to monitor the application
gem 'okcomputer'
gem 'solrizer',   '~> 2.2'
gem 'sul_chrome', '~> 0.1.0'

gem 'sass-rails',     '~> 3.2.3'
gem 'coffee-rails',   '~> 3.2.1'
gem 'bootstrap-sass', '2.3.2.1'
gem 'therubyracer'
gem 'libv8', '~> 3.16.14.19'  # dep of therubyracer
gem 'uglifier', '>= 1.0.3'

# gems only needed for particular environments

group :development, :test do
  gem 'jettywrapper', '1.4.2'
  gem 'sqlite3'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'capybara'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'equivalent-xml', '~> 0.5.1'
  gem 'awesome_print'
  gem 'launchy'
  gem 'byebug'
  gem 'letter_opener'
# gem 'database_cleaner'
  gem 'pry'
end

group :development do
  gem 'quiet_assets'
end

group :production, :dortest do
  gem 'mysql2'
  gem 'activerecord-mysql-adapter'
end

group :deployment do
  gem 'capistrano', '~> 3.3'
  gem 'capistrano-rails'
  gem 'dlss-capistrano'
end

# Ruby 2.2+ has removed test/unit from the core library. Rails requires this as a dependency
# Rails 3.2 uses ActiveSupport::Test case in lib/rails/console/app.rb, so we need it in all groups
gem 'test-unit'

gem 'honeybadger'
