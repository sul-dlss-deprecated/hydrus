module Hydrus::EmbargoMetadataDsExtension
  
  def world_release_access_node_xml
    return <<-XML
    <releaseAccess>
  		<access type="discover">
  			<machine>
  				<world />
  			</machine>
  		</access>
  		<access type="read">
  			<machine>
  				<world/>
  			</machine>
  		</access>
  	</embargoAccess>
    XML
  end
  
  def stanford_release_access_node_xml
    return <<-XML
    <releaseAccess>
  		<access type="discover">
  			<machine>
  				<world />
  			</machine>
  		</access>
  		<access type="read">
  			<machine>
  				<group>stanford</group>
  			</machine>
  		</access>
  	</embargoAccess>
    XML
  end
  
end