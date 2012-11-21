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
#       <access type="edit">
#         <machine/>
#       </access>

module Hydrus::Accessible

  # An Xpath snippet that is used frequently.
  def xp_machine(type = 'read')
    return '//access[@type="read"]/machine'
  end

  # Takes a group (for example, 'stanford').
  # Adds a group read node.
  def add_read_group(group)
    q = "#{xp_machine}/group[text()='#{group}']"
    unless ng_xml.at_xpath(q)
      g = "<group>#{group}</group>"
      ng_xml.at_xpath(xp_machine).add_child(g)
      content_will_change!
    end
  end

  # Removes all group read nodes and world read nodes.
  # Replaces them with a world read node.
  def make_world_readable
    remove_group_read_nodes
    remove_world_read_access
    ng_xml.at_xpath(xp_machine).add_child('<world/>')
    content_will_change!
  end

  # Returns true if there is a world read node.
  def has_world_read_node
    return world_read_nodes.size > 0
  end

  # Returns all world read nodes -- should be only one.
  def world_read_nodes
    q = "#{xp_machine}/world"
    return ng_xml.xpath(q)
  end

  # Returns all group read nodes.
  def group_read_nodes
    q = "#{xp_machine}/group"
    return ng_xml.xpath(q)
  end

  # Removes group read nodes.
  def remove_group_read_nodes
    q = "#{xp_machine}/group"
    remove_nodes_by_xpath(q)
    content_will_change!
  end

  # Removes world read nodes.
  def remove_world_read_access
    q = "#{xp_machine}/world"
    remove_nodes_by_xpath(q)
    content_will_change!
  end

  # Removes the embargo date node.
  # Note that the Xpath query differs by datastream.
  def remove_embargo_date
    q = "#{xp_machine}/embargoReleaseDate"
    q = "//embargoMetadata/releaseDate" if self.class == Dor::EmbargoMetadataDS
    remove_nodes_by_xpath(q)
  end

  # Takes a group -- typically 'world' or 'stanford'.
  # Modifies the datastream accordingly.
  def update_access_blocks(group)
    if group == "world"
      make_world_readable
    else
      remove_world_read_access
      add_read_group(group)
    end
  end

  # Initializes the releaseAccess node for embargoMetadata.
  def initialize_release_access_node(style = nil)
    x = style == :generic ? generic_access_xml() : "<releaseAccess/>"
    self.release_access_node = Nokogiri::XML(x)
    content_will_change!
  end

  # The Generic <releaseAccess> node for embargoMetadata.
  def generic_access_xml
    return <<-XML
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
