set :rails_env, "development"
set :deployment_host, "hydrus-dev.stanford.edu"
set :repository, File.expand_path(File.join(File.dirname(Pathname.new(__FILE__).realpath), "../.."))
set :deploy_via, :copy
set :branch, "develop"
set :bundle_without, [:deployment]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

set :git_enable_submodules, 1
namespace :jetty do
  task :start do 
    run "cd #{deploy_to}/current && rake hydra:jetty:config && rake jetty:start"
  end
  task :stop do
    run "cd #{deploy_to}/current && rake jetty:stop"
  end
  task :ingest_fixtures do
    run "cd #{deploy_to}/current && rake hydrus:loadfix"
  end
end

namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end

before "deploy", "jetty:stop"
after "deploy", "jetty:start"
after "jetty:start", "jetty:ingest_fixtures"
