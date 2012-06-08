class Hydrus::RelatedItem < Hydrus::GenericModel
  
  attr_accessor :title, :url

  def self.new_from_node(related_item_node)
    # Takes a Nokogiri <relatedItem> node.
    # Returns a new Hydrus::RelatedItem object.
    title_node = related_item_node.at_css('titleInfo title')
    url_node   = related_item_node.at_css('location url')
    url        = url_node   ? url_node.content   : ''
    link_label = title_node ? title_node.content : url
    return Hydrus::RelatedItem.new(:title => link_label, :url => url)
  end

end
