# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
# require 'capistrano/rvm'
# require 'capistrano/rbenv'
# require 'capistrano/chruby'
# require 'capistrano/bundler'
# require 'capistrano/rails/assets'
# require 'capistrano/rails/migrations'

require 'squash/rails/capistrano3'

# Monkey-patch around https://github.com/SquareSquash/rails/pull/11
set :_squash_current_revision, lambda {
  rev = nil
  on roles(:web), :in => :sequence, :limit => 1 do
    within repo_path do
      origin = capture("git ls-remote #{fetch(:repo_url)}").chomp.lines.map { |l| l.split(/\s+/) }.index_by(&:last)
      rev    = origin["refs/heads/#{fetch :branch}"].try(:first) || capture("git rev-parse #{fetch :branch}").chomp
    end
  end
  rev
}

require 'capistrano/bundler'
require 'capistrano/rails'
require "whenever/capistrano"
require 'dlss/capistrano'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
