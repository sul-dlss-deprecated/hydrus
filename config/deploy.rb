require "rvm/capistrano"                               # Load RVM's capistrano plugin.
require 'net/ssh/kerberos'
require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'
require 'pathname'

set :stages, %W(burndown dev testing prod)
set :default_stage, "testing"
set :bundle_flags, "--quiet"
set :rvm_ruby_string, "1.9.3@hydrus"
set :rvm_type, :system

require 'capistrano/ext/multistage'

after "deploy:assets:symlink", "rvm:trust_rvmrc"
#after "deploy:restart", "dlss:log_release"

set :shared_children, %w(log config/certs config/environments config/database.yml config/solr.yml config/fedora.yml config/suri.yml)

set :user, "lyberadmin" 
set :runner, "lyberadmin"
set :ssh_options, {:auth_methods => %w(gssapi-with-mic publickey hostbased), :forward_agent => true}

set :destination, "/var/home/lyberadmin"
set :application, "hydrus"

set :scm, :git
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 2

set :deploy_to, "#{destination}/#{application}"

namespace :rvm do
  task :trust_rvmrc do
    run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
  end
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after "deploy", "deploy:migrate"
