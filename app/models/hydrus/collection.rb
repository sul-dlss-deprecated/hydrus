class Hydrus::Collection < Hydrus::GenericObject
  
  # TODO:  not working properly yet!
  def related_items
puts descMetadata.find_by_terms(:relatedItem).inspect
    @related_items ||= descMetadata.find_by_terms(:relatedItem).collect {|rel_node| 
      title_node = rel_node.at_css('titleInfo title')
      url_node = rel_node.at_css('identifier')
      url = url_node ? url_node.content : nil
      link_label = title_node ? title_node.content : url
      Hydrus::RelatedItem.new(:title => link_label, :url => url)
    }
  end

end
