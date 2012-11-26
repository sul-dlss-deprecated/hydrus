module Hydrus::EmbargoMetadataDsExtension

end

module Dor
  class EmbargoMetadataDS < ActiveFedora::NokogiriDatastream

    include Hydrus::GenericDS
    include Hydrus::Accessible

    # The dor-services gem provides a getter and setter for release_date, but
    # they do not suit Hydrus readily, so we are writing our own.

    def release_date=(rd)
      update_values([:release_date] => HyTime.datetime(rd))
      content_will_change!
    end

    def release_date
      term_values(:release_date).first
    end

  end
end
