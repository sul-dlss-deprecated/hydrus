# Override make_solr_connection() so that we don't need certs in dev and test.
#if %w(development test prod_w_local_dor).include?(Rails.env)
  module Dor
    class Configuration
      def make_solr_connection(add_opts = {})
        opts = Config.solrizer.opts.merge(add_opts).merge(:url => Config.solrizer.url)
        ::RSolr.connect(opts).extend(RSolr::Ext::Client)
      end
    end
  end
#end


Dor::Config.configure do

  load_yaml_config = lambda { |yaml_file|
    full_path = File.expand_path(File.join(File.dirname(__FILE__), '..', yaml_file))
    yaml      = YAML.load(File.read full_path)
    return yaml[Rails.env]
  }

  fedora do
    # Set the fedora URL with user and password info.
    yaml = load_yaml_config.call('fedora.yml')
    user = yaml['user']
    pw   = yaml['password']
    url yaml['url'].sub /:\/\//, "://#{user}:#{pw}@"
  end
  
  suri do
    mint_ids true
    id_namespace 'druid'
    yaml = load_yaml_config.call('suri.yml')
    url yaml['url']
    user yaml['user']
    pass yaml['password']
  end
  
  yaml = load_yaml_config.call('solr.yml')
  solrizer.url yaml['url']
    
  # TODO: this URL will need to vary by environment.
  workflow.url 'http://lyberservices-dev.stanford.edu/workflow/'

  # TODO: this druid will need to vary by environment.
  ur_apo_druid 'druid:oo000oo0000'

  hydrus do
    workflow_steps({
      :hydrusAssemblyWF => [
        { :name => "start-deposit",   :status => "completed", :lifecycle => "registered" },
        { :name => "submit",          :status => "waiting" },
        { :name => "approve",         :status => "waiting" },
        { :name => "start-assembly",  :status => "waiting" },
      ],
      :assemblyWF => [
        { :name => "start-assembly",        :status => "completed", :lifecycle => "inprocess" },
        { :name => "jp2-create",            :status => "completed", },
        { :name => "checksum-compute",      :status => "waiting" },
        { :name => "exif-collect",          :status => "waiting" },
        { :name => "accessioning-initiate", :status => "waiting" },
      ],
      :accessionWF => [
        { :name => "start-accession",      :status => "completed", :lifecycle => "submitted" },
        { :name => "content-metadata",     :status => "waiting" },
        { :name => "descriptive-metadata", :status => "waiting",   :lifecycle => "described" },
        { :name => "rights-metadata",      :status => "waiting" },
        { :name => "technical-metadata",   :status => "waiting" },
        { :name => "provenance-metadata",  :status => "waiting" },
        { :name => "remediate-object",     :status => "waiting" },
        { :name => "shelve",               :status => "waiting" },
        { :name => "publish",              :status => "waiting",   :lifecycle => "published" },
        { :name => "sdr-ingest-transfer",  :status => "waiting" },
        { :name => "cleanup",              :status => "waiting",   :lifecycle => "accessioned" },
      ],
    })
  end

end
