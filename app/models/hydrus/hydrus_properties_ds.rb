class Hydrus::HydrusPropertiesDS < ActiveFedora::NokogiriDatastream

  include Hydrus::GenericDS
  include SolrDocHelper

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

  define_template :user do |xml,username,date_accepted|
      xml.user(username,:dateAccepted => date_accepted)
  end

  define_template :accepted_terms_of_deposit do |xml|
      xml.acceptedTermsOfDeposit
  end

  # Empty XML document.
  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.hydrusProperties
    end.doc
  end
  
  def insert_user_accepting_terms_of_deposit(user,date_accepted)
    root_node=find_by_terms(:accepted_terms_of_deposit).first
    if root_node.nil?
      root_node=add_hydrus_child_node(ng_xml.root,:accepted_terms_of_deposit)
    end
    add_hydrus_child_node(root_node, :user, user, date_accepted)
  end

end
