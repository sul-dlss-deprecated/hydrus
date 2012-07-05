class Hydrus::AdministrativeMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper

  set_terminology do |t|
    t.root :path => 'administrativeMetadata', :index_as => [:not_searchable]
    t.relationships :index_as => [:not_searchable]
    t.hydrus :index_as => [:not_searchable] do
      t.depositStatus
      t.reviewRequired
      t.termsOfDeposit
      t.embargo { t.option :path => {:attribute => 'option'} }
      t.release { t.option :path => {:attribute => 'option'} }
      t.license { t.option :path => {:attribute => 'option'} }
    end
  end
  
  # Empty XML document.

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.administrativeMetadata {
        xml.relationships
        xml.hydrus {
          xml.depositStatus
          xml.reviewRequired
          xml.termsOfDeposit
          xml.embargo
          xml.release
          xml.license
        }
      }
    end.doc
  end
      
end
