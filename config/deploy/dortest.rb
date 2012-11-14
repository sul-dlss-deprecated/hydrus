set :rails_env, "dortest"
set :deployment_host, "hydrus-test.stanford.edu"
set :repository, "https://github.com/sul-dlss/hydrus.git"
set :deploy_via, :remote_cache
DEFAULT_TAG='develop'
set :bundle_without, [:deployment, :development]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy", "files:create_upload_symlink"
# after "deploy", "files:refresh_fixtures"
after "deploy", "solr:reindex_workflow_objects"
after "deploy", "app:add_date_to_version"
