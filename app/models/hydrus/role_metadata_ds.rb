class Hydrus::RoleMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper
  
  set_terminology do |t|
    t.root :path => 'roleMetadata'

    t.actor do
      t.identifier do
        t.type_ :path => {:attribute => 'type'}
      end
      t.name
    end
    t.person :ref => [:actor], :path => 'person'
    t.group  :ref => [:actor], :path => 'group'
    
    t.person_id :proxy => [:person, :identifier]

    t.role do
      t.type_ :path => {:attribute => 'type'}
      t.person :ref => [:person]
      t.group  :ref => [:group]
    end
    
    # APO roles
    t.collection_manager   :ref => [:role], :attributes => {:type => 'collection-manager'}
    t.collection_owner    :proxy => [:collection_manager, :person, :identifier]
    t.collection_depositor :ref => [:role], :attributes => {:type => 'collection-depositor'}
    t.collection_reviewer  :ref => [:role], :attributes => {:type => 'collection-reviewer'}
    t.collection_viewer    :ref => [:role], :attributes => {:type => 'collection-viewer'}
    # item object roles
    t.item_depositor       :ref => [:role], :attributes => {:type => 'item-depositor'}
  end

  def get_person_role(person_id)
    self.find_by_xpath("/roleMetadata/role[person/identifier='#{person_id}']/@type").text
  end

  def to_solr(solr_doc=Hash.new, *args)
    self.find_by_xpath('/roleMetadata/role/*').each do |actor|
      role_type = toggle_hyphen_underscore(actor.parent['type'])
      val = [actor.at_xpath('identifier/@type'),actor.at_xpath('identifier/text()')].join ':'
      add_solr_value(solr_doc, "apo_role_#{actor.name}_#{role_type}", val, :string, [:searchable, :facetable])
      add_solr_value(solr_doc, "apo_role_#{role_type}", val, :string, [:searchable, :facetable])
      if ['collection_manager','collection_depositor'].include? role_type
        add_solr_value(solr_doc, "apo_register_permissions", val, :string, [:searchable, :facetable])
      end
    end
    solr_doc
  end

  # Takes a string       (eg, item-foo or collection_bar)
  # Returns a new string (eg, item_foo or collection-bar).
  TOGGLE_HYPHEN_REGEX = / \A (collection|item) ([_\-]) ([a-z]) /ix
  def toggle_hyphen_underscore(role_type)
    role_type.sub(TOGGLE_HYPHEN_REGEX) { "#{$1}#{$2 == '_' ? '-' : '_'}#{$3}" }
  end

  # Adding/removing nodes.

  # if the role node exists, add the person node to it; 
  #  otherwise, create the role node and then add the person node.  
  def add_person_with_role(id, role_type)
    role_node = self.find_by_xpath("/roleMetadata/role[@type='#{role_type}']")
    if role_node.size == 0
      new_role_node = insert_role(role_type)
      return insert_person(new_role_node, id)
    else
      return insert_person(role_node, id)
    end
  end  

  # if the role node exists, add an empty person node to it; 
  #  otherwise, create the role node and then add an empty person node
  def add_empty_person_to_role(role_type)
    add_person_with_role("", role_type)
  end  

  def insert_role(role_type)
    add_hydrus_child_node(ng_xml.root, :role, role_type)
  end

  def insert_person(role_node, sunetid)
    add_hydrus_child_node(role_node, :person, sunetid)
  end

  def insert_group(role_node, group_type)
    add_hydrus_child_node(role_node, :group, group_type)
  end

  # TODO: need to promote this code to some generic place for all of our stuff AND/OR put it in OM
  #   will be put in OM/ActiveFedora.  See also DescMetadataDS and specs
  # Set dirty=true. Otherwise, inserting repeated nodes does not work.
  def add_hydrus_child_node(*args)
    node = add_child_node(*args)
    self.dirty = true  
    return node
  end

  # TODO: need to promote this code to some generic place for all of our stuff AND/OR put it in OM
  #   will be put in OM/ActiveFedora.  See also DescMetadataDS and specs
  def remove_nodes(term)
    nodes = find_by_terms(term.to_sym)
    nodes.each { |n| n.remove }
    self.dirty = true
  end

# FIXME: write test
  def delete_actor(identifier)
    person_node = self.find_by_xpath("/roleMetadata/role/person[identifier='#{identifier}']")
    person_node.remove
    self.dirty = true
  end

  # OM templates.

  define_template :role do |xml, role_type|
    xml.role(:type => role_type)
  end

  define_template :person do |xml, sunetid|
    xml.person {
      xml.identifier(:type => 'sunetid') { xml.text(sunetid) }
      xml.name
    }
  end

  define_template :group do |xml, group_type|
    xml.group {
      xml.identifier(:type => group_type)
      xml.name
    }
  end

  # Empty XML document.

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.roleMetadata
    end.doc
  end

end
