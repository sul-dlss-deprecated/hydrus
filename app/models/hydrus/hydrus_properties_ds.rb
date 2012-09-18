class Hydrus::HydrusPropertiesDS < ActiveFedora::NokogiriDatastream

  include Hydrus::GenericDS
  
  set_terminology do |t|
    t.root :path => 'hydrusProperties'
    
    t.accepted_terms_of_deposit :path => 'acceptedTermsOfDeposit'
    t.date_accepted_terms_of_deposit :path=> 'dateAcceptedTermsOfDeposit'
    t.requires_human_approval :path => 'requiresHumanApproval'
    t.disapproval_reason :path => 'disapprovalReason'
  end

  # Empty XML document.
  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.hydrusProperties
    end.doc
  end

end
