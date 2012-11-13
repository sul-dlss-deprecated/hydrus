require "rvm/capistrano"                               # Load RVM's capistrano plugin.
require 'net/ssh/kerberos'
require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'
require 'pathname'

set :stages, %W(burndown dev dortest prod)
set :default_stage, "dortest"
set :bundle_flags, "--quiet"
set :rvm_ruby_string, "1.9.3@hydrus"
set :rvm_type, :system

require 'capistrano/ext/multistage'

after "deploy:assets:symlink", "rvm:trust_rvmrc"
#after "deploy:restart", "dlss:log_release"

set :shared_children, %w(
  log 
  config/certs
  config/database.yml
  config/solr.yml
  config/fedora.yml
  config/suri.yml
  config/ur_apo_druid.yml
  config/workflow.yml
  config/ssl_certs.yml
)

set :user, "lyberadmin" 
set :runner, "lyberadmin"
set :ssh_options, {
  :auth_methods  => %w(gssapi-with-mic publickey hostbased),
  :forward_agent => true
}

set :destination, "/var/home/lyberadmin"
set :application, "hydrus"

set :scm, :git
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 2

set :deploy_to, "#{destination}/#{application}"

set :branch do
# DEFAULT_TAG = `git tag`.split("\n").last
  tag = Capistrano::CLI.ui.ask "Tag or branch to deploy (make sure to push the tag or branch first): [#{DEFAULT_TAG}] "
  tag = DEFAULT_TAG if tag.empty?
  tag
end

namespace :rvm do
  task :trust_rvmrc do
    run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
  end
end

namespace :app do
  task :add_date_to_version do
    run "cd #{deploy_to}/current && date >> VERSION"
  end
end

namespace :jetty do
  task :start do 
    run "cd #{deploy_to}/current && rake hydra:jetty:config && rake jetty:start"
  end
  task :stop do
    run "if [ -d #{deploy_to}/current ]; then cd #{deploy_to}/current && rake jetty:stop; fi"
  end
  task :ingest_fixtures do
    run "cd #{deploy_to}/current && rake hydrus:refreshfix RAILS_ENV=#{rails_env}"
  end
end

namespace :db do
  task :loadfixtures do
    run "cd #{deploy_to}/current && rake db:fixtures:load RAILS_ENV=#{rails_env}"
  end
end

namespace :solr do
  task :reindex_workflow_objects do
    run "cd #{deploy_to}/current && rake hydrus:reindex_workflow_objects RAILS_ENV=#{rails_env}"
  end
end

namespace :files do
  task :refresh_fixtures do
    run "cd #{deploy_to}/current && rake hydrus:refresh_upload_files"
  end  
  task :create_upload_symlink do
   run "ln -s /data/hydrus-files #{deploy_to}/current/public/uploads" 
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
