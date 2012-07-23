class Hydrus::AdministrativeMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper
  include Hydrus::GenericDS

  set_terminology do |t|
    t.root :path => 'administrativeMetadata', :index_as => [:not_searchable]
    t.relationships :index_as => [:not_searchable]
    t.hydrus :index_as => [:not_searchable] do
      t.depositStatus
      t.reviewRequired
      t.termsOfDeposit
      t.embargo    { t.option :path => {:attribute => 'option'} }
      t.visibility { t.option :path => {:attribute => 'option'} }
      t.license    { t.option :path => {:attribute => 'option'} }
    end
    t.hydrusAssembly do
      t.workflow do
        t.process {
          t.name      :path => {:attribute => 'name'}
          t.status    :path => {:attribute => 'status'}
          t.lifecycle :path => {:attribute => 'lifecycle'}
        }
      end
    end

  end
  
  def insert_hydrus_assembly_wf
    add_hydrus_child_node(ng_xml.root, :hydrus_assembly_wf)
  end

  define_template(:hydrus_assembly_wf) do |xml|
    xml.hydrusAssembly {
      xml.workflow(:id => 'hydrusAssemblyWF') {
        Dor::Config.hydrus_assembly_wf_steps.each do |step|
          xml.process(step)
        end
      }
    }
  end

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.administrativeMetadata {
        xml.relationships
        xml.hydrus {
          xml.depositStatus
          xml.reviewRequired
          xml.termsOfDeposit
          xml.embargo
          xml.visibility
          xml.license
        }
      }
    end.doc
  end
      
end
