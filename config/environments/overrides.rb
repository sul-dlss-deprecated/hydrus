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
    url Hydrus.fedora_yaml['url_auth']
  end
  solrizer.url "http://localhost:8983/solr/#{Rails.env}"
  workflow.url 'http://lyberservices-dev.stanford.edu/workflow/'
end
