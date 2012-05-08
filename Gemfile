source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem 'dor-services', ">= 3.5.1"
gem 'blacklight', '~> 3.3.1'
gem 'hydra-head', '~> 4.0.0'
gem 'devise'

group :test do 
  gem "cucumber-rails", :require => false
  gem 'database_cleaner', :require => false
  gem 'rspec-rails', '>=2.9.0', :require => false
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end

group :development, :test do
  gem 'jettywrapper'
end

#group :deployment do
#  gem 'capistrano'
##  gem 'capistrano-ext'
#  gem 'rvm-capistrano'
#  gem 'lyberteam-devel', '>=0.7.0'
##  gem 'net-ssh-kerberos'
#end

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem "compass-rails", "~> 1.0.0", :group => :assets
gem "compass-susy-plugin", "~> 0.9.0", :group => :assets

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
#gem 'ruby-debug19', :require => 'ruby-debug'
