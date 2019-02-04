ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Override Solrizer logger before it gets a chance to load and pollute STDERR.
require 'solrizer'
solr_log = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'solrizer.log'))
Solrizer.logger = Logger.new solr_log
Solrizer.logger.level = Logger::INFO
