require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'
require 'pathname'

set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { rails_env }
require "whenever/capistrano"

set :stages, %W(burndown development dortest production)
set :default_stage, "dortest"
set :bundle_flags, "--quiet"

set :repository, "https://github.com/sul-dlss/hydrus.git"
set :deploy_via, :remote_cache

require 'capistrano/ext/multistage'

set :shared_children, %w(
  log
  config/certs
  config/database.yml
  config/dor_services.yml
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
  default = `git describe --abbrev=0`.strip # Most recent Git tag.
  msg = "Tag or branch to deploy (be sure to push it first): [#{default}] "
  tag = Capistrano::CLI.ui.ask(msg)
  tag.empty? ? default : tag
end

namespace :jetty do
  task :start do
    run "cd #{deploy_to}/current && rake hydra:jetty:config && rake jetty:start"
  end
  task :stop do
    run "if [ -d #{deploy_to}/current ]; then cd #{deploy_to}/current && rake jetty:stop; fi"
  end
  task :ingest_fixtures do
    run "cd #{deploy_to}/current && bundle exec rake hydrus:refreshfix RAILS_ENV=#{rails_env}"
  end
end

namespace :db do
  task :loadfixtures do
    run "cd #{deploy_to}/current && bundle exec rake db:fixtures:load RAILS_ENV=#{rails_env}"
  end
end

namespace :solr do
  task :reindex_workflow_objects do
    run "cd #{deploy_to}/current && bundle exec rake hydrus:reindex_workflow_objects RAILS_ENV=#{rails_env}"
  end
end

namespace :files do
  task :refresh_fixtures do
    run "cd #{deploy_to}/current && bundle exec rake hydrus:refresh_upload_files"
  end
  task :create_upload_symlink do
   run "ln -s /data/hydrus-files #{deploy_to}/current/public/uploads"
  end
  task :cleanup_tmp do
    run "cd #{deploy_to}/current && bundle exec rake hydrus:cleanup_tmp RAILS_ENV=#{rails_env}"
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
after "deploy", "files:create_upload_symlink"
after "deploy", "solr:reindex_workflow_objects"
after "deploy:update", "deploy:cleanup" 