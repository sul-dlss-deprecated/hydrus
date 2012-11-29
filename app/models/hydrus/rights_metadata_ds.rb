class Hydrus::RightsMetadataDS < ActiveFedora::NokogiriDatastream

  include Hydrus::GenericDS
  include Hydrus::Accessible

  set_terminology do |t|
    t.root :path => 'rightsMetadata'

    t.access do
      t.human
      t.machine do
        t.world
        t.group
        t.embargo_release_date(:path => "embargoReleaseDate")
      end
    end

    t.discover_access :ref => [:access], :attributes => {:type => "discover"}
    t.read_access     :ref => [:access], :attributes => {:type => "read"}
    t.edit_access     :ref => [:access], :attributes => {:type => "edit"}

    t.use do
      t.human
      t.machine
    end
  end

  define_template :creative_commons do |xml|
    xml.use {
      xml.human(:type => "creativeCommons")
      xml.machine(:type => "creativeCommons")
    }
  end

  define_template :open_data_commons do |xml|
    xml.use {
      xml.human(:type => "openDataCommons")
      xml.machine(:type => "openDataCommons")
    }
  end

  def insert_creative_commons
    add_hydrus_child_node(ng_xml.root, :creative_commons)
  end

  def insert_open_data_commons
    add_hydrus_child_node(ng_xml.root, :open_data_commons)
  end

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.rightsMetadata{
        xml.access(:type => "discover") {
          xml.machine {
            xml.world # at Stanford metadata is publicly visible by policy
          }
        }
        xml.access(:type => "read") {
          xml.machine
        }

        xml.access(:type => "edit") {
          xml.machine
        }
        xml.use {
          xml.human
          xml.machine
        }
      }
    end.doc
  end

end
