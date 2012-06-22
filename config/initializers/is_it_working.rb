require 'uri'
require 'nokogiri'
require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check the ActiveRecord database connection without spawning a new thread
  h.check :active_record, :async => false

  # Check that AwesomeService is working using the service's own logic
  h.check :rubydora, :client => ActiveFedora::Base.connection_for_pid(0)
  h.check :rsolr, :client => Blacklight.solr
end unless $0 =~ /rake$/
