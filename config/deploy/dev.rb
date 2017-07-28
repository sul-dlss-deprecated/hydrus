# frozen_string_literal: true

server 'hydrus-dev.stanford.edu', user: 'lyberadmin', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'development'

set :bundle_without, %w{test deployment}.join(' ')
