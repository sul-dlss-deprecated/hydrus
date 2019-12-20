require 'dor-services'

Dor.registered_classes['adminPolicy'] = Hydrus::AdminPolicyObject
Dor.registered_classes['collection'] = Hydrus::Collection
Dor.registered_classes['item'] = Hydrus::Item

Dor.configure do
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

  solr.url Settings.solr.url

  stacks do
    document_cache_host         Settings.stacks.document_cache_host
    local_workspace_root        Settings.stacks.local_workspace_root
  end
end
