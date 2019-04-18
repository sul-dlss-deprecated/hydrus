module Dor
  class Abstract
    # need to override if we want to use the Hydra access permissions code
    has_metadata name: 'rightsMetadata', type: Hydra::Datastream::RightsMetadata, label: 'Rights Metadata'
  end
end
