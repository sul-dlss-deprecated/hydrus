server 'sul-hydrus-stage.stanford.edu', user: 'hydrus', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "production"
