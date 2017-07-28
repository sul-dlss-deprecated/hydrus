# Load the rails application
require File.expand_path('../application', __FILE__)

current_path=File.dirname(__FILE__)
no_solr_cert=(%w{development dortest test prod_w_local_dor}.include?(Rails.env))

# Override make_solr_connection() so that we use POST for solr queries
require File.expand_path(File.join(current_path, 'rsolr_no_certificate'))

Hydrus::Application.configure do

  # this is the path from the root of the public folder into which file uploads will be stored
  config.file_upload_path = 'uploads'

  # file attributes by mimetype, including defaults, to use when generating content metadata
  config.cm_file_attributes = {
    'default' => {publish: 'yes',preserve: 'yes',shelve: 'yes'}
  }
  config.cm_file_attributes_hidden = {publish: 'no',preserve: 'yes',shelve: 'no'}

  # style of content metadata to generate
  config.cm_style = :file

end

require 'dor-services'
Dor.configure do
  app_version File.read File.join(current_path, '..','VERSION')

  fedora do
    url Settings.fedora.url
  end

  suri do
    mint_ids Settings.suri.mint_ids
    id_namespace('druid')
    url Settings.suri.url
    user Settings.suri.user
    pass Settings.suri.password
  end

  # Using client certificates for connections is optional
  if Settings.ssl
    ssl do
      key_file Settings.ssl.key_file if Settings.ssl.key_file
      cert_file Settings.ssl.cert_file if Settings.ssl.cert_file
      key_pass Settings.ssl.key_pass if Settings.ssl.key_pass
    end
  end

  workflow do
    url     Settings.workflow.url
    timeout Settings.workflow.timeout
  end

  dor_services.url Settings.dor_services.url
  solr.url     Settings.solr.url
  sdr.url          Settings.sdr.url

  hydrus do
    initial_apo_title      'Intial Hydrus APO title'
    app_workflow           'hydrusAssemblyWF'
    app_workflow_steps     %w(start-deposit submit approve start-assembly)
    ur_apo_druid           Settings.hydrus.ur_apo_druid
    assembly_wf_xml        File.read(File.join(current_path, 'assemblyWF_hydrus.xml'))
    show_standard_login    Settings.hydrus.show_standard_login   # if true, the user has the option to login via a username/password as well as webauth; if false; only webauth is allowed
    exception_error_page   Settings.hydrus.exception_error_page  # if true, a generic error page will be shown with no exception messages; if false, standard Rails exceptions are shown directly to the user
    exception_error_panel  Settings.hydrus.exception_error_panel # if true and exception_error_page is also set to true, a collapsible exception error panel is shown on the friendly error page
    exception_recipients   Settings.hydrus.exception_recipients  # list of email addresses, comma separated, that will be notified when an exception occurs - leave blank for no emails
    host                   Settings.hydrus.host                  # server host, used in emails
    start_assembly_wf      Settings.hydrus.start_assembly_wf     # determines if assembly workflow is started when publishing

    # complete list of all workflow objects defined in this environment
    workflow_object_druids Settings.hydrus.workflow_object_druids
  end

  purl do
    base_url Settings.purl.base_url
  end

  stacks do
    document_cache_storage_root Settings.stacks.document_cache_storage_root
    document_cache_host         Settings.stacks.document_cache_host
    document_cache_user         Settings.stacks.document_cache_user
    local_workspace_root        Settings.stacks.local_workspace_root
    storage_root                Settings.stacks.storage_root
    host                        Settings.stacks.host
    user                        Settings.stacks.user
  end

end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Initialize the rails application
Hydrus::Application.initialize!


require 'hydrus'
