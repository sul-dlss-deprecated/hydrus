class Hydrus::Item < Hydrus::GenericObject

  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight')  # coming from the database
  end
  
  def preferred_citation
    descMetadata.preferred_citation.first
  end
    
  def keywords
    @keywords ||= descMetadata.subject.topic.collect {|topic| topic}   
  end
      
  def actors
    @actors ||= descMetadata.find_by_terms(:name).collect {|name_node| Hydrus::Actor.new(:name=>name_node.at_css('namePart').content,:role=>name_node.at_css('role roleTerm').content)}
  end
  
  def submit_time
    query = '//workflow[@id="sdrDepositWF"]/process[@name="submit"]'
    time=workflows.ng_xml.at_xpath(query)
    return (time ? time['datetime'] : nil)
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
