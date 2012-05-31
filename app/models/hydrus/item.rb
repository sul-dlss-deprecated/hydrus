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
      
  def publisher
    descMetadata.originInfo.publisher.first
  end
  
  def publication_date
    descMetadata.originInfo.dateIssued.first
  end
  
  def peer_reviewed
    descMetadata.peer_reviewed.first
  end
 
  def url
    "http://purl.stanford.edu/#{pid}"
  end
  
  def related_items
    @related_items ||= descMetadata.find_by_terms(:relatedItem).collect {|rel_node| Hydrus::RelatedItem.new(:title=>rel_node.at_css('titleInfo title').content,:url=>rel_node.at_css('identifier').content)}
  end
  
  def actors
    @actors ||= descMetadata.find_by_terms(:name).collect {|name_node| Hydrus::Actor.new(:name=>name_node.at_css('namePart').content,:role=>name_node.at_css('role roleTerm').content)}
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
