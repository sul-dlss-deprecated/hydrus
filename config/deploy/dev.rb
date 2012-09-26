set :rails_env, "development"
set :deployment_host, "hydrus-dev.stanford.edu"
set :repository, File.expand_path(File.join(File.dirname(Pathname.new(__FILE__).realpath), "../.."))
set :deploy_via, :copy
DEFAULT_TAG='develop'
set :bundle_without, [:deployment]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

set :git_enable_submodules, 1

namespace :deploy do
  namespace :assets do
    task :symlink do ; end
    task :precompile do ; end
  end
end

before "deploy", "jetty:stop"
after "deploy", "jetty:start"
after "deploy", "db:loadfixtures"
after "jetty:start", "jetty:ingest_fixtures"
