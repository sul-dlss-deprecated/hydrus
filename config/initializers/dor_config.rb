require 'dor-services'

Dor.registered_classes['adminPolicy'] = Hydrus::AdminPolicyObject
Dor.registered_classes['collection'] = Hydrus::Collection
Dor.registered_classes['item'] = Hydrus::Item

Dor.configure do
  fedora do
    url Settings.fedora.url
  end

  # Using client certificates for connections is optional
  if Settings.ssl
    ssl do
      key_file Settings.ssl.key_file if Settings.ssl.key_file
      cert_file Settings.ssl.cert_file if Settings.ssl.cert_file
      key_pass Settings.ssl.key_pass if Settings.ssl.key_pass
    end
  end

  solr do
    url Settings.solr.url
  end

  stacks do
    local_workspace_root Settings.stacks.local_workspace_root
  end
end
