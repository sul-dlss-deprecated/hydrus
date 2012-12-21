# Load the rails application
require File.expand_path('../application', __FILE__)

current_path=File.dirname(__FILE__)
no_solr_cert=(%w{development dortest test prod_w_local_dor}.include?(Rails.env))

# Override make_solr_connection() so that we don't need certs in dev and test.
require File.expand_path(File.join(current_path, 'rsolr_no_certificate')) if no_solr_cert

Hydrus::Application.configure do

  # this is the path from the root of the public folder into which file uploads will be stored
  config.file_upload_path = 'uploads'

  config.cm_file_attributes = {'default'=>{:publish=>'yes',:preserve=>'yes',:shelve=>'yes'}} # file attributes by mimetype, including defaults, to use when generating content metadata
  config.cm_style = :file # style of content metadata to generate

end

Dor::Config.configure do

  cert_dir File.join(current_path, "certs")

  app_version File.read File.join(current_path, '..','VERSION')

  load_yaml_config = lambda { |yaml_file|
    full_path = File.expand_path(File.join(current_path, yaml_file))
    yaml      = YAML.load(File.read full_path)
    return yaml[Rails.env]
  }

  fedora do
    # Set the fedora URL with user and password info.
    yaml = load_yaml_config.call('fedora.yml')
    user = yaml['user']
    pw   = yaml['password']
    fedora_url = yaml['url']
    if !(user.blank? || pw.blank?)
      url fedora_url.sub /:\/\//, "://#{user}:#{pw}@"
    else
      url fedora_url
    end
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

  yaml = load_yaml_config.call('workflow.yml')
  workflow.url yaml['url']

  yaml = load_yaml_config.call('solr.yml')
  solrizer.url yaml['url']

  hydrus do
    initial_apo_title('Intial Hydrus APO title')
    app_workflow(:hydrusAssemblyWF)
    ur_apo_druid(load_yaml_config.call('ur_apo_druid.yml')['druid'])
  end

end

# Initialize the rails application
Hydrus::Application.initialize!

require File.expand_path(File.join(current_path, 'rsolr_certificate')) unless no_solr_cert

require 'hydrus'
