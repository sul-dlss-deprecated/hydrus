class Hydrus::RelatedItem < Hydrus::GenericModel
  
  def self.new_from_node(related_item_node)
    # Takes a Nokogiri <relatedItem> node.
    # Returns a new Hydrus::RelatedItem object.
    title_node = related_item_node.at_css('titleInfo title')
    url_node   = related_item_node.at_css('location url')
    url        = (url_node.respond_to?(:content) and !url_node.content.blank?)     ? url_node.content : ''
    link_label = (title_node.respond_to?(:content) and !title_node.content.blank?) ? title_node.content : url
    return Hydrus::RelatedItem.new(:title => link_label, :url => url)
  end

end
