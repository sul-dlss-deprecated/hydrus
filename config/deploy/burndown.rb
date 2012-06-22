set :rails_env, "development"
set :deployment_host, "dlss-dev-#{ENV['USER']}.stanford.edu"
set :repository, File.expand_path(File.join(File.dirname(Pathname.new(__FILE__).realpath), "../.."))
set :deploy_via, :copy
set :branch, "develop"
set :bundle_without, [:deployment]
set :user, ENV['USER']
set :runner, ENV['USER']
set :git_enable_submodules, 1

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

