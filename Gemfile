source 'https://rubygems.org'
source 'http://sul-gems.stanford.edu'

gem 'dor-services'
gem 'druid-tools', '>= 0.2.0'
gem 'sul_chrome'
gem 'about_page'
gem 'is_it_working-cbeer', "~> 1.0.13"
gem 'assembly-objectfile', ">= 1.5.0"
gem 'rsolr-client-cert', ">= 0.5.2"
gem 'solrizer-fedora'

gem 'blacklight', '~>3.5', :git => 'http://github.com/projectblacklight/blacklight.git'
gem 'hydra-head', '~> 4.1.1'
gem 'rubydora',   '~> 0.5.11'

gem 'devise'
gem 'carrierwave'
gem 'rails', '3.2.11'
gem 'jquery-rails'
gem 'dynamic_form'
gem 'bootstrap-datepicker-rails'
gem 'cancan'
gem 'validates_email_format_of'
gem 'coderay'
gem 'whenever'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'compass_twitter_bootstrap'
  gem "compass-rails", "~> 1.0.0"
  gem "compass-susy-plugin", "~> 0.9.0"
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer'
  gem 'uglifier', '>= 1.0.3'
end

# gems only needed for particular environments

group :test do
  gem "cucumber-rails"
  gem 'database_cleaner'
  gem 'rspec-rails', '>=2.9.0'
  gem 'simplecov'
  gem 'simplecov-rcov'
end

group :development, :test do
  gem 'jettywrapper'
  gem 'sqlite3'
  gem 'awesome_print'
  gem 'launchy'
  gem 'ruby-prof', :platform => 'ruby_19'
  gem 'debugger', :platform => 'ruby_19'
	gem 'letter_opener'
end

group :development do
  gem 'looksee', :platform => 'ruby_19'
	gem 'newrelic_rpm'
end

group :production, :dortest do
  gem 'mysql2'
  gem 'activerecord-mysql-adapter'
end

gem 'quiet_assets', :group => :development

