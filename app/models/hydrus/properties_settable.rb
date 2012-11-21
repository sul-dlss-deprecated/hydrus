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

  # Returns visibility as an array -- typically either ['world'] or ['stanford'].
  # Embargo status determines which datastream is used to obtain the information.
  def visibility
    ds = is_embargoed ? embargoMetadata : rightsMetadata
    return ["world"] if ds.has_world_read_node
    return ds.group_read_nodes.map { |n| n.text }
  end

  # Takes a visibility -- typically 'world' or 'stanford'.
  # Modifies the embargoMetadata and rightsMetadata based on that visibility
  # values, along with the embargo status.
  def visibility= val
    if is_embargoed
      # If embargoed, we set access info in embargoMetadata.
      embargoMetadata.initialize_release_access_node(:generic)
      embargoMetadata.update_access_blocks(val)
      # And we clear our read access in rightsMetadata.
      rightsMetadata.remove_world_read_access
      rightsMetadata.remove_group_read_nodes
    else
      # Otherwise, we clear out embargoMetadata.
      embargoMetadata.initialize_release_access_node()
      # And set access info in rightsMetadata.
      rightsMetadata.remove_embargo_date
      rightsMetadata.update_access_blocks(val)
    end
  end

  # Returns the embargo date from the embargoMetadata, not the rightsMetadata.
  # The latter is a convenience copy used by the PURL app.
  def embargo_date
    return embargoMetadata.release_date
  end

  # Sets the embargo date in both embargoMetadata and rightsMetadata.
  def embargo_date= val
    ed = HyTime.datetime(val, :from_localtime => true)
    embargoMetadata.release_date  = ed
    self.rmd_embargo_release_date = ed
  end

end
