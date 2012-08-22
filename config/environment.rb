# Load the rails application
require File.expand_path('../application', __FILE__)

if %w{development test prod_w_local_dor}.include?(Rails.env) 
  require File.expand_path(File.join(File.dirname(__FILE__), 'override_solr_connection'))
end

Dor::Config.configure do

  cert_dir File.join(File.dirname(__FILE__), "certs")

  load_yaml_config = lambda { |yaml_file|
    full_path = File.expand_path(File.join(File.dirname(__FILE__), yaml_file))
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
  
  ssl do
    yaml = load_yaml_config.call('ssl_certs.yml')
    key_file File.join(Dor::Config.cert_dir,yaml['key_file']) if yaml['key_file']
    cert_file File.join(Dor::Config.cert_dir,yaml['cert_file']) if yaml['key_file']
    key_pass yaml['key_pass'] 
  end
  
  yaml = load_yaml_config.call('ur_apo_druid.yml')
  ur_apo_druid yaml['druid']
  
  yaml = load_yaml_config.call('workflow.yml')
  workflow.url yaml['url']
  
  yaml = load_yaml_config.call('solr.yml')
  solrizer.url yaml['url']

  hydrus do
    initial_apo_title('Intial Hydrus APO title')
    app_workflow(:hydrusAssemblyWF)
    start_common_assembly(true)

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

# Initialize the rails application
Hydrus::Application.initialize!

require 'hydrus'
