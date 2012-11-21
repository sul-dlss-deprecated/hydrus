module Hydrus::EmbargoMetadataDsExtension
  
end

module Dor
  class EmbargoMetadataDS < ActiveFedora::NokogiriDatastream

    include Hydrus::GenericDS
    include Hydrus::Accessible

    def release_date=(rd)
      update_values([:release_date] => HyTime.datetime(rd))
      content_will_change!
    end
    
    def release_date
      term_values(:release_date).first
    end
    
  end
end
