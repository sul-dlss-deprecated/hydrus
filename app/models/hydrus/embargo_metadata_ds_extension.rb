module Hydrus::EmbargoMetadataDsExtension

end

module Dor
  class EmbargoMetadataDS < ActiveFedora::OmDatastream

    include Hydrus::GenericDS
    include Hydrus::Accessible

  end
end
