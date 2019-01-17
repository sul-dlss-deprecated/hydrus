# frozen_string_literal: true

class XmlHelperService
  attr_reader :datastream

  def initialize(datastream:)
    @datastream = datastream
  end

  def add_hydrus_child_node(*args)
    node = datastream.add_child_node(*args)
    datastream.ng_xml_will_change!
    node
  end

  # Adds a node to a datastream, as a next sibling if possible.
  # The first argument is the OM term to find the sibling.
  # The rest of the arguments are passed to the OM method that
  # does the work of adding the node.
  def add_hydrus_next_sibling_node(sib_term, *args)
    sibling = datastream.find_by_terms(sib_term).last
    node = sibling ? datastream.add_next_sibling_node(sibling, *args) :
                     datastream.add_child_node(datastream.ng_xml.root, *args)
    datastream.ng_xml_will_change!
    node
  end

  def remove_node(term, index)
    node = datastream.find_by_terms(term.to_sym => index.to_i).first
    unless node.nil?
      node.remove
      datastream.ng_xml_will_change!
    end
  end

  def remove_nodes(*terms)
    terms = terms.map { |t| t.to_sym }
    nodes = datastream.find_by_terms(*terms)
    if nodes.size > 0
      nodes.each { |n| n.remove }
      datastream.ng_xml_will_change!
    end
  end

  def remove_nodes_by_xpath(query)
    nodes = datastream.find_by_xpath(query)
    if nodes.size > 0
      nodes.each { |n| n.remove }
      datastream.ng_xml_will_change!
    end
  end
end
