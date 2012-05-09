require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

module Hydrus
  def self.fedora_yaml
    # Load fedora.yml for the current environment.
    yfile = File.expand_path(File.join(File.dirname(__FILE__), 'fedora.yml'))
    yaml  = YAML.load(File.read yfile)[Rails.env]

    # Add an item to the hash: the fedora URL with user name and password.
    user  = yaml['user']
    pw    = yaml['password']
    yaml['url_auth'] = yaml['url'].sub /:\/\//, "://#{user}:#{pw}@"

    return yaml
  end
end
