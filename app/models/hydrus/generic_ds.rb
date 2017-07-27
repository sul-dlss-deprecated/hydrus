module Hydrus::GenericDS

  # TODO: Considering putting these methods in OM or ActiveFedora.

  def add_hydrus_child_node(*args)
    node = add_child_node(*args)
    ng_xml_will_change!
    return node
  end

  # Adds a node to a datastream, as a next sibling if possible.
  # The first argument is the OM term to find the sibling.
  # The rest of the arguments are passed to the OM method that
  # does the work of adding the node.
  def add_hydrus_next_sibling_node(sib_term, *args)
    sibling = find_by_terms(sib_term).last
    node = sibling ? add_next_sibling_node(sibling, *args) :
                     add_child_node(ng_xml.root, *args)
    ng_xml_will_change!
    return node
  end

  def remove_node(term, index)
    node = find_by_terms(term.to_sym => index.to_i).first
    unless node.nil?
      node.remove
      ng_xml_will_change!
    end
  end

  def remove_nodes(*terms)
    terms = terms.map { |t| t.to_sym }
    nodes = find_by_terms(*terms)
    if nodes.size > 0
      nodes.each { |n| n.remove }
      ng_xml_will_change!
    end
  end

  def remove_nodes_by_xpath(query)
    nodes = find_by_xpath(query)
    if nodes.size > 0
      nodes.each { |n| n.remove }
      ng_xml_will_change!
    end
  end

end
