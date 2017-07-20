require 'okcomputer'

# /status for 'upness' (Rails app is responding), e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

# REQUIRED checks, required to pass for /status/all
#  individual checks also avail at /status/<name-of-check>
OkComputer::Registry.register 'ruby_version', OkComputer::RubyVersionCheck.new

# Solr
OkComputer::Registry.register 'solr_url', OkComputer::HttpCheck.new(Dor::Config.solrizer.url)

# fedora
OkComputer::Registry.register 'fedora_url', OkComputer::HttpCheck.new(Dor::Config.fedora.url)

# suri
OkComputer::Registry.register 'fedora_url', OkComputer::HttpCheck.new(Dor::Config.suri.url)

# dor-services-app
about_url = Dor::Config.dor_services.url + '/v1/about'
OkComputer::Registry.register 'dor_services_url', OkComputer::HttpCheck.new(about_url)

# Local filesystem public/uploads -> shared/public/uploads -> /data/hydrus-files
OkComputer::Registry.register 'document_cache_root', OkComputer::DirectoryCheck.new('public/uploads')