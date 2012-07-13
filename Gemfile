source :rubygems
source "http://sulair-rails-dev.stanford.edu"

# def dor_services_gem_params
#   p = '/afs/ir/dev/dlss/git/lyberteam/dor-services-gem.git'
#   if ENV['USE_LOCAL_DOR_SERVICES']
#     return { :path => ENV['USE_LOCAL_DOR_SERVICES'] }
#   elsif ENV['USE_SSH_OVER_OPENAFS_PATH']
#     return { :git => "ssh://corn.stanford.edu#{p}", :branch => 'hydrus' }
#   else
#     return { :git => p, :branch => 'hydrus' }
#   end
# end

gem 'dor-services', ">= 3.5.1"  # , dor_services_gem_params
gem 'druid-tools'
gem 'sul_chrome'
gem 'about_page'
gem 'is_it_working-cbeer', "~> 1.0.13"

gem 'blacklight', '~>3.5', :git => 'http://github.com/projectblacklight/blacklight.git'
gem 'hydra-head', '~> 4.1.1'
gem 'devise'
gem 'carrierwave'
gem 'rails', '3.2.3'
gem 'jquery-rails'
gem 'dynamic_form'

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
  gem 'awesome_print'
  gem 'looksee'
  gem 'debugger'
  gem 'sqlite3'
end

group :production do
  gem 'mysql'
end

gem 'quiet_assets', :group => :development

#group :deployment do
#  gem 'capistrano'
##  gem 'capistrano-ext'
#  gem 'rvm-capistrano'
#  gem 'lyberteam-devel', '>=0.7.0'
##  gem 'net-ssh-kerberos'
#end
