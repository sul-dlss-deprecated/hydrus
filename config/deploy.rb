set :application, 'hydrus'
set :repo_url, 'https://github.com/sul-dlss/hydrus.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/app/hydrus/hydrus'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w(
  config/database.yml
  config/blacklight.yml
  config/honeybadger.yml
  config/secrets.yml
)

# Default value for linked_dirs is []
set :linked_dirs, %w{log config/certs config/settings tmp/pids tmp/cache tmp/sockets vendor/bundle public/system uploads}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :bundle_without, %w{development test deployment}.join(' ')

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, fetch(:stage)

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'

namespace :deploy do
  after :restart, :clear_tmp do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        with rails_env: fetch(:rails_env) do
          rake 'hydrus:cleanup_tmp'
        end
      end
    end
  end
end
