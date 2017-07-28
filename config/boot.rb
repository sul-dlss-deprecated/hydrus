# frozen_string_literal: true

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# Override Solrizer logger before it gets a chance to load and pollute STDERR.
require 'solrizer'
solr_log = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'solrizer.log'))
Solrizer.logger = Logger.new solr_log
Solrizer.logger.level = Logger::INFO

