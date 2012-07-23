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
    
  workflow.url 'http://lyberservices-dev.stanford.edu/workflow/'

  # TODO: this druid will probably need to vary by environment.
  ur_apo_druid 'druid:oo000oo0000'

  hydrus_assembly_wf_steps [
    { :name => "start-deposit",   :status => "completed", :lifecycle => "registered" },
    { :name => "submit",          :status => "waiting", },
    { :name => "approve",         :status => "waiting", },
    { :name => "start-accession", :status => "waiting", },
  ]

end
