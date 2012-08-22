# Override make_solr_connection() so that we don't need certs in dev and test.
module Dor
  class Configuration
    def make_solr_connection(add_opts = {})
      opts = Config.solrizer.opts.merge(add_opts).merge(:url => Config.solrizer.url)
      ::RSolr.connect(opts).extend(RSolr::Ext::Client)
    end
  end
end