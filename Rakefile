#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Hydrus::Application.load_tasks

# clear the default task injected by rspec
task(:default).clear

# and replace it with our own
task default: [:ci]
