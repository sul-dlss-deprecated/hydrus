set :rails_env, "dortest"
set :deployment_host, "hydrus-test.stanford.edu"
set :bundle_without, [:deployment, :development]

DEFAULT_TAG='develop'

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
