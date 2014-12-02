source 'https://rubygems.org'

gem 'rails', '~> 3.2.22'
gem "druid-tools", "~> 0.4.0"
gem 'dor-workflow-service'
gem 'addressable', '2.3.5'
gem "moab-versioning", "~> 1.4"
gem 'dor-services', "~> 4.21"
gem 'sul_chrome', '~> 0.1.0'
gem 'about_page'
gem 'is_it_working-cbeer', "~> 1.0.13"
gem 'assembly-objectfile', "1.5.0"
gem 'blacklight', '~>4.4'
gem 'hydra-head', '~> 5.1', '>= 5.4.1'
gem 'active-fedora', "~> 5.7.1"
gem 'solrizer', '~> 2.2'
gem 'devise', '~> 2.2.5'
gem 'carrierwave', "0.6.2"
gem 'jquery-rails'
gem 'dynamic_form'
gem 'bootstrap-datepicker-rails'
gem 'cancan'
gem 'validates_email_format_of'
gem 'coderay'
gem 'whenever', "~> 0.9"

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem "bootstrap-sass", '2.3.2.1'
  gem 'therubyracer'
  gem 'libv8', '=3.16.14.7'  # dep of therubyracer fails to compile (bad C code) in '3.16.14.9'
  gem 'uglifier', '>= 1.0.3'
end

# gems only needed for particular environments

group :development, :test do
  gem 'jettywrapper', '1.4.1'
  gem 'sqlite3'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'capybara'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'awesome_print'
  gem 'launchy'
  gem 'ruby-prof', :platform => 'ruby_19'
  gem 'debugger',  :platform => 'ruby_19'
  gem 'byebug',    :platform => 'ruby_20'
  gem 'letter_opener'
  gem 'equivalent-xml'
  gem 'database_cleaner'
end

group :development do
  gem 'looksee', :platform => 'ruby_19'
  gem 'quiet_assets'
end

group :production, :dortest do
  gem 'mysql2'
  gem 'activerecord-mysql-adapter'
end

group :deployment do
  gem 'capistrano', "~> 3.0"
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel'
end

gem 'squash_ruby', :require => 'squash/ruby'
gem 'squash_rails', ">= 1.3.3", :require => 'squash/rails'

