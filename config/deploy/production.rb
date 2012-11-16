set :rails_env, "production"
set :deployment_host, "hydrus-prod.stanford.edu"
set :bundle_without, [:deployment,:development,:test]

DEFAULT_TAG='master'

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
