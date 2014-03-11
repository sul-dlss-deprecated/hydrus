set :rails_env, "dortest"
set :deployment_host, "hydrus-test.stanford.edu"
set :bundle_without, [:deployment, :development]
set :branch, "dor-services-upgrade"

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy:update", "files:cleanup_tmp"