class Hydrus::Item < Hydrus::GenericItem

  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight')  # coming from the database
  end
  
  def submit_time
    query = '//workflow[@id="sdrDepositWF"]/process[@name="submit"]'
    return workflows.ng_xml.at_xpath(query)['datetime']
  end
  
  def add_to_collection(pid)
    uri = "info:fedora/#{pid}"
    add_relationship_by_name('set', uri)
    add_relationship_by_name('collection', uri)
  end

  def remove_from_collection(pid)
    uri = "info:fedora/#{pid}"
    remove_relationship_by_name('set', uri)
    remove_relationship_by_name('collection', uri)
  end

end
