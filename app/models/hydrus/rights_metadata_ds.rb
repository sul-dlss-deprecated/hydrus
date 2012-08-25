class Hydrus::RightsMetadataDS < ActiveFedora::NokogiriDatastream
  include Hydrus::GenericDS
 
  RM_NS = "http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1"

  set_terminology do |t|
    t.root :path => 'rightsMetadata', :xmlns => RM_NS, :version => "0.1"
    
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
  def insert_creative_commons
    add_hydrus_child_node(ng_xml.root, :creative_commons)
  end
  
  define_template :open_data_commons do |xml|
    xml.use {
      xml.human(:type => "openDataCommons")
      xml.machine(:type => "openDataCommons")
    } 
  end
  
  def insert_open_data_commons
    add_hydrus_child_node(ng_xml.root, :open_data_commons)
  end
  
  def add_read_group(group)
    ns = "xmlns:"
    unless ng_xml.at_xpath("//#{ns}access[@type='read']/#{ns}machine/#{ns}group[text()='#{group}']")
      ng_xml.at_xpath("//#{ns}access[@type='read']/#{ns}machine").add_child("<group>#{group}</group>")
      content_will_change!
    end
  end
  
  def make_world_readable
    remove_all_group_read_nodes
    ns = "xmlns:"
    q  = "//#{ns}access[@type='read']/#{ns}machine/#{ns}world"
    remove_nodes_by_xpath(q)
    read_access.machine.world = ""
  end
  
  def remove_world_read_access
    remove_world_node("read")
    content_will_change!
  end
  
  def remove_all_group_read_nodes
    ns = "xmlns:"
    q  = "//#{ns}access[@type='read']/#{ns}machine/#{ns}group"
    remove_nodes_by_xpath(q)
  end
  
  def remove_world_node(type)
    ns = "xmlns:"
    q = "/#{ns}rightsMetadata/#{ns}access[@type='#{type}']/#{ns}machine/#{ns}world"
    remove_nodes_by_xpath(q)
  end
  
  def remove_group_node(type,group)
    ns = "xmlns:"
    q = "/#{ns}rightsMetadata/#{ns}access[@type='#{type}']/#{ns}machine/#{ns}group[text()='#{group}']"
    remove_nodes_by_xpath(q)
  end
  
  def remove_embargo_date
    ns = "xmlns:"
    q = "/#{ns}rightsMetadata/#{ns}access[@type='read']/#{ns}machine/#{ns}embargoReleaseDate"
    remove_nodes_by_xpath(q)
  end
  
  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.rightsMetadata(:xmlns=>RM_NS, :version => "0.1"){
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
