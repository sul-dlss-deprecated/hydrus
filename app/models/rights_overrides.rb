module Dor
  module Publishable

    # need to override if we want to use the Hydra access permissions code
    included do
      has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata, :label => 'Rights Metadata'
    end
end