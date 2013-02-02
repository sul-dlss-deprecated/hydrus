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
      t.human {
        t.type_ :path => {:attribute => 'type'}
      }
      t.machine {
        t.type_ :path => {:attribute => 'type'}
      }
    end

    t.terms_of_use :ref => [:use, :human], :attributes => { :type => "useAndReproduction" }

  end

  # Template to do the work of insert_license().
  define_template :license do |xml, gcode, code, txt|
    xml.human(  :type => gcode) { xml.text(txt) }
    xml.machine(:type => gcode) { xml.text(code) }
  end

  # Takes a license-group code, a license code, and the corresponding license text.
  # Adds the nodes for that license to the <use> node.
  def insert_license(gcode, code, txt)
    use_node = use.nodeset.first || ng_xml.root
    add_hydrus_child_node(use_node, :license, gcode, code, txt)
  end

  # Remove license-related nodes.
  def remove_license
    q = '//use/*[@type!="useAndReproduction"]'
    remove_nodes_by_xpath(q)
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
          xml.human(:type => "useAndReproduction")
        }
      }
    end.doc
  end

end
