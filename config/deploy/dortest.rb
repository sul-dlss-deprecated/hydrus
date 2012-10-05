set :rails_env, "dortest"
set :deployment_host, "hydrus-test.stanford.edu"
set :repository, File.expand_path(File.join(File.dirname(Pathname.new(__FILE__).realpath), "../.."))
set :deploy_via, :copy
DEFAULT_TAG='develop'
set :bundle_without, [:deployment, :development]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy", "db:loadfixtures"
after "deploy", "hydrus:refresh_upload_files"