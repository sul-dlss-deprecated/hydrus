# frozen_string_literal: true

require 'okcomputer'
require 'faraday'
# Check an HTTP connection with client certificates
class HttpWithClientKeyCheck < OkComputer::Check
  ConnectionFailed = Class.new(StandardError)

  attr_accessor :url, :request_timeout

  # Public: Initialize a new HTTP check.
  #
  # url - The URL to check
  # request_timeout - How long to wait to connect before timing out. Defaults to 5 seconds.
  def initialize(url, request_timeout = 5)
    self.url = url
    self.request_timeout = request_timeout
  end

  # TODO: it would be great if there was a method in dor-services for this
  def client_cert
    Dor::Config.fedora.client.options[:ssl_client_cert]
  end

  # TODO: it would be great if there was a method in dor-services for this
  def client_key
    Dor::Config.fedora.client.options[:ssl_client_key]
  end

  def connection
    Faraday::Connection.new url, ssl: { client_cert: client_cert,
                                        client_key: client_key }
  end

  def resource
    Timeout.timeout(request_timeout) do
      connection.get(url)
    end
  rescue => e
    raise ConnectionFailed, e
  end

  # Public: Return the status of the HTTP check
  def check
    if resource.status == 200
      mark_message 'HTTP check successful'
    else
      mark_message "Error: Status code is #{resource.status}"
      mark_failure
    end
  rescue => e
    mark_message "Error: '#{e}'"
    mark_failure
  end
end

# /status for 'upness' (Rails app is responding), e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

# REQUIRED checks, required to pass for /status/all
#  individual checks also avail at /status/<name-of-check>
OkComputer::Registry.register 'ruby_version', OkComputer::RubyVersionCheck.new

# Solr
solr_url = Dor::Config.solr.url + '/select'
OkComputer::Registry.register 'solr_url', OkComputer::HttpCheck.new(solr_url)

# fedora
OkComputer::Registry.register 'fedora_url', HttpWithClientKeyCheck.new(Dor::Config.fedora.url)

# suri
suri_url = URI(Dor::Config.suri.url + '/suri2/namespaces')
suri_url.userinfo = [Dor::Config.suri.user, Dor::Config.suri.pass].join(':')
OkComputer::Registry.register 'suri_url', OkComputer::HttpCheck.new(suri_url.to_s)

# dor-services-app
about_url = Dor::Config.dor_services.url + '/v1/about'
OkComputer::Registry.register 'dor_services_url', OkComputer::HttpCheck.new(about_url)

# Local filesystem public/uploads -> shared/public/uploads -> /data/hydrus-files
OkComputer::Registry.register 'document_cache_root', OkComputer::DirectoryCheck.new('public/uploads')
