# A module used to read and modify the <access> nodes that
# exist in rightsMetadata and in embargoMetadata/releaseAccess.
#
# For reference, here are some example <access> nodes:
#
#       <access type="discover">
#         <machine>
#           <world/>
#         </machine>
#       </access>
#       <access type="read">
#         <machine>
#           <group>stanford</group>
#         </machine>
#       </access>

module Hydrus::Accessible
  # An Xpath snippet that is used frequently.
  def xp_machine(type = 'read')
    '//access[@type="' + type + '"]/machine'
  end

  # Takes a group (for example, 'stanford').
  # Adds a group read node.
  def add_read_group(group)
    remove_access_none_nodes
    q = "#{xp_machine}/group[text()='#{group}']"
    unless ng_xml.at_xpath(q)
      g = "<group>#{group}</group>"
      ng_xml.at_xpath(xp_machine).add_child(g)
      ng_xml_will_change!
    end
  end

  # Removes all group read nodes and world read nodes.
  # Replaces them with a world read node.
  def make_world_readable
    remove_access_none_nodes
    remove_group_read_nodes
    remove_world_read_access
    ng_xml.at_xpath(xp_machine).add_child('<world/>')
    ng_xml_will_change!
  end

  # Removes all group read nodes and world read nodes.
  # Replaces them with deny read access for all (required for embargoed info in rightsMetadata)
  def deny_read_access
    remove_group_read_nodes
    remove_world_read_access
    add_access_none_node
  end

  # Returns true if there is a world read node.
  def has_world_read_node
    world_read_nodes.size > 0
  end

  # Returns all world read nodes -- should be only one.
  def world_read_nodes
    q = "#{xp_machine}/world"
    ng_xml.xpath(q)
  end

  # Returns all group read nodes.
  def group_read_nodes
    q = "#{xp_machine}/group"
    ng_xml.xpath(q)
  end

  # Removes group read nodes.
  def remove_group_read_nodes
    q = "#{xp_machine}/group"
    remove_nodes_by_xpath(q)
  end

  # Add access <none/> node to read (remove any existing to avoid dupes)
  def add_access_none_node
    remove_access_none_nodes
    ng_xml.at_xpath(xp_machine).add_child('<none/>')
    ng_xml_will_change!
  end

  # Removes access = none nodes
  def remove_access_none_nodes
    q = "#{xp_machine}/none"
    remove_nodes_by_xpath(q)
  end

  # Removes world read nodes.
  def remove_world_read_access
    q = "#{xp_machine}/world"
    remove_nodes_by_xpath(q)
  end

  # Removes the embargo date node.
  # Note that the Xpath query differs by datastream.
  def remove_embargo_date
    q = "#{xp_machine}/embargoReleaseDate"
    q = '//embargoMetadata/releaseDate' if self.class == Dor::EmbargoMetadataDS
    remove_nodes_by_xpath(q)
    remove_access_none_nodes
  end

  # Takes a group -- typically 'world' or 'stanford'.
  # Modifies the datastream accordingly.
  def update_access_blocks(group)
    remove_access_none_nodes
    if group == 'world'
      make_world_readable
    else
      remove_world_read_access
      add_read_group(group)
    end
  end

  # Initializes the releaseAccess node for embargoMetadata.
  def initialize_release_access_node(style = nil)
    x = style == :generic ? generic_access_xml() : '<releaseAccess/>'
    self.release_access_node = Nokogiri::XML(x)
    ng_xml_will_change!
  end

  # The Generic <releaseAccess> node for embargoMetadata.
  def generic_access_xml
    <<-XML
      <releaseAccess>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine/>
        </access>
      </embargoAccess>
    XML
  end
end
