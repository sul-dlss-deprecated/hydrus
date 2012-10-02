class Hydrus::HydrusPropertiesDS < ActiveFedora::NokogiriDatastream

  include Hydrus::GenericDS
  
  set_terminology do |t|
    t.root :path => 'hydrusProperties'
    
    t.accepted_terms_of_deposit(:path => 'acceptedTermsOfDeposit') do
      t.user do
        t.date_accepted :path=> {:attribute => 'dateAccepted'}
      end 
    end
  
    t.requires_human_approval :path => 'requiresHumanApproval'
    t.reviewed_release_settings :path=>'reviewedReleaseSettings'
    t.disapproval_reason :path => 'disapprovalReason'
    
    t.collection_depositor :path => 'collectionDepositor'
  end

  # Empty XML document.
  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.hydrusProperties
    end.doc
  end

end
