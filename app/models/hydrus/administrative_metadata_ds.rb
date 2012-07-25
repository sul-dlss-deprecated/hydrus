class Hydrus::AdministrativeMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper
  include Hydrus::GenericDS

  def self.short_wf(wf_name)
    # Used to convert a workflow ID to the name of the parent node in
    # the APO adminMD. For example:
    #   :hydrusAssemblyWF >> 'hydrusAssembly'
    return wf_name.to_s[0..-3]
  end

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

    # Define OM terms for all of the workflows.
    Dor::Config.hydrus.workflow_steps.keys.each do |wf_name|
      t.send(Hydrus::AdministrativeMetadataDS.short_wf(wf_name)) do
        t.workflow do
          t.process {
            t.name      :path => {:attribute => 'name'}
            t.status    :path => {:attribute => 'status'}
            t.lifecycle :path => {:attribute => 'lifecycle'}
          }
        end
      end
    end

  end
 
  def insert_workflow(wf_name)
    add_hydrus_child_node(ng_xml.root, wf_name)
  end

  # Call define_template() for all of the workflows.
  Dor::Config.hydrus.workflow_steps.each do |wf_name, steps|
    define_template(wf_name) do |xml|
      xml.send(Hydrus::AdministrativeMetadataDS.short_wf(wf_name)) {
        xml.workflow(:id => wf_name.to_s) {
          steps.each { |s| xml.process(s) }
        }
      }
    end
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
