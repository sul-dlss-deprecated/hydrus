set :rails_env, "production"
set :deployment_host, "hydrus-prod.stanford.edu"
set :repository, "https://github.com/sul-dlss/hydrus.git"
set :deploy_via, :remote_cache
DEFAULT_TAG='master'
set :bundle_without, [:deployment,:development,:test]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
