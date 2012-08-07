module Hydrus::EmbargoMetadataDsExtension
  
  def generic_release_access_xml
    return <<-XML
    <releaseAccess>
  		<access type="discover">
  			<machine>
  				<world />
  			</machine>
  		</access>
  		<access type="read">
  			<machine/>
  		</access>
  	</embargoAccess>
    XML
  end
  
end

module Dor
  class EmbargoMetadataDS < ActiveFedora::NokogiriDatastream
        
    def add_read_group(group)
      unless ng_xml.at_xpath('//access[@type="read"]/machine/group[text()="' << group << '"]')
        ng_xml.at_xpath('//access[@type="read"]/machine').add_child("<group>#{group}</group>")
        content_will_change!
      end
    end
    
    def make_world_readable
      find_by_xpath('//access[@type="read"]/machine/group').each do |node|
        node.remove
      end
      add_world_read_access
      content_will_change!
    end
    
    def add_world_read_access
      unless ng_xml.at_xpath('//access[@type="read"]/machine/world')
        ng_xml.at_xpath('//access[@type="read"]/machine').add_child("<world/>")
        content_will_change!
      end
    end
    
    def remove_world_read_access
      if find_by_xpath("//access[@type='read']/machine/world")
        find_by_xpath("//access[@type='read']/machine/world").remove 
        content_will_change!
      end
    end
    
    def remove_embargo_date
      if ng_xml.at_xpath("//embargoMetadata/releaseDate")
        term_value_delete(:select => '//embargoMetadata/releaseDate')
        content_will_change!
      end
    end
  end
end