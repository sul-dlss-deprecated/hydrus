module Hydrus::PropertiesSettable

  def license *args
    rightsMetadata.use.machine(*args).first
  end

  def license= val
    rightsMetadata.remove_nodes(:use)
    Hydrus::Collection.licenses.each do |type,licenses|
      licenses.each do |license|
        if license.last == val
          # TODO I would like to do this type_attribute part better.
          # Maybe infer the insert method and call send on rightsMetadata.
          type_attribute = Hydrus::Collection.license_commons[type]
          if type_attribute == "creativeCommons"
            rightsMetadata.insert_creative_commons
          elsif type_attribute == "openDataCommons"
            rightsMetadata.insert_open_data_commons
          end
          rightsMetadata.use.machine = val
          rightsMetadata.use.human = license.first
        end
      end
    end
  end

  def visibility *args
    groups = []
    if embargo == "future"
      if embargoMetadata.release_access_node.at_xpath('//access[@type="read"]/machine/world')
        groups << "world"
      else
        node = embargoMetadata.release_access_node.at_xpath('//access[@type="read"]/machine/group')
        groups << node.text if node
      end
    else
      (rightsMetadata.read_access.machine.group).collect{|g| groups << g}
      (rightsMetadata.read_access.machine.world).collect{|g| groups << "world" if g.blank?}
    end
    groups
  end

  def visibility= val
    embargoMetadata.release_access_node = Nokogiri::XML(generic_release_access_xml) unless embargoMetadata.ng_xml.at_xpath("//access")
    if embargo == "immediate"
      embargoMetadata.release_access_node = Nokogiri::XML("<releaseAccess/>")
      rightsMetadata.remove_embargo_date
      embargoMetadata.remove_embargo_date
      update_access_blocks(rightsMetadata, val)
    elsif embargo == "future"
      rightsMetadata.remove_world_read_access
      rightsMetadata.remove_all_group_read_nodes
      update_access_blocks(embargoMetadata, val)
      embargoMetadata.release_date = Date.strptime(embargo_date, "%m/%d/%Y") unless embargo_date.blank?
    end
  end

  def embargo_date *args
    date = (rightsMetadata.read_access.machine.embargo_release_date *args).first
    return "" if date.blank?
    begin
      return Date.parse(date).strftime("%m/%d/%Y") 
    rescue
      return ""
    end
  end

  def embargo_date= val
    begin
      date = val.blank? ? "" : Date.strptime(val, "%m/%d/%Y").to_s
    rescue
      date=""
    end
    (rightsMetadata.read_access.machine.embargo_release_date= date)
  end

end