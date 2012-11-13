AboutPage.configure do |config|
  config.app = { :name => 'Hydrus', :version => Dor::Config.app_version }

  config.dependencies = AboutPage::Dependencies.new

  config.environment = AboutPage::Environment.new({ 
    'Ruby' => /^(RUBY|GEM_|rvm)/,
    'Rails' => /^*/
  })

  config.request = AboutPage::RequestEnvironment.new({
    'HTTP Server' => /^(SERVER_|POW_)/,
    'WebAuth' => /^WEBAUTH_/
  })
  
  config.fedora = AboutPage::Fedora.new(ActiveFedora::Base.connection_for_pid(0))
  config.solr = AboutPage::Solr.new(Blacklight.solr)
end unless $0 =~ /rake$/
