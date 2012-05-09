# Override make_solr_connection() so that we don't need certs in dev and test.
if %w(development test).include?(Rails.env)
  module Dor
    class Configuration
      def make_solr_connection(add_opts = {})
        opts = Config.solrizer.opts.merge(add_opts).merge(:url => Config.solrizer.url)
        ::RSolr.connect(opts).extend(RSolr::Ext::Client)
      end
    end
  end
end


Dor::Config.configure do
  fedora do
    # Load fedora.yml for the current environment.
    yfile = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fedora.yml'))
    yaml  = YAML.load(File.read yfile)[Rails.env]
    # Set the fedora URL with user and password info.
    user  = yaml['user']
    pw    = yaml['password']
    url yaml['url'].sub /:\/\//, "://#{user}:#{pw}@"
  end

  yfile = File.expand_path(File.join(File.dirname(__FILE__), '..', 'solr.yml'))
  yaml  = YAML.load(File.read yfile)[Rails.env]
  solrizer.url yaml['url']

  workflow.url 'http://lyberservices-dev.stanford.edu/workflow/'
end
