class Hydrus::Collection < Hydrus::GenericObject
  
  def hydrus_items
    query = %Q(is_member_of_collection_s:"info:fedora/#{pid}")
    resp  = Blacklight.solr.find('q.alt'.to_sym => query)
    items = resp.docs.map { |d| Hydrus::Item.find(d.id) }
    return items
  end

end
