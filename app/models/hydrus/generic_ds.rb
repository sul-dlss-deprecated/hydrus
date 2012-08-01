module Hydrus::GenericDS
  
  # TODO: Considering putting these methods in OM or ActiveFedora.

  def add_hydrus_child_node(*args)
    node = add_child_node(*args)
    content_will_change!
    return node
  end

  def remove_node(term, index)
    node = find_by_terms(term.to_sym => index.to_i).first
    unless node.nil?
      node.remove
      content_will_change!
    end
  end

  def remove_nodes(*terms)
    terms = terms.map { |t| t.to_sym }
    nodes = find_by_terms(*terms)
    nodes.each { |n| n.remove }
    content_will_change!
  end

end
