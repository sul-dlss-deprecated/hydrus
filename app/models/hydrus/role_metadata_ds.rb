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

    t.role do
      t.type_ :path => {:attribute => 'type'}
      t.person :ref => [:person]
      t.group  :ref => [:group]
    end
    
    t.collection_manager   :ref => [:role], :attributes => {:type => 'collection_manager'}
    t.item_manager         :ref => [:role], :attributes => {:type => 'item_manager'}
    t.collection_depositor :ref => [:role], :attributes => {:type => 'collection_depositor'}
    t.item_depositor       :ref => [:role], :attributes => {:type => 'item_depositor'}
    t.collection_reviewer  :ref => [:role], :attributes => {:type => 'collection_reviewer'}
    t.collection_viewer    :ref => [:role], :attributes => {:type => 'collection_viewer'}
  end

  def to_solr(solr_doc=Hash.new, *args)
    self.find_by_xpath('/roleMetadata/role/*').each do |actor|
      role_type = actor.parent['type']
      val = [actor.at_xpath('identifier/@type'),actor.at_xpath('identifier/text()')].join ':'
      add_solr_value(solr_doc, "apo_role_#{actor.name}_#{role_type}", val, :string, [:searchable, :facetable])
      add_solr_value(solr_doc, "apo_role_#{role_type}", val, :string, [:searchable, :facetable])
      if ['collection_manager','collection_depositor'].include? role_type
        add_solr_value(solr_doc, "apo_register_permissions", val, :string, [:searchable, :facetable])
      end
    end
    solr_doc
  end

  # OM templates.

  define_template :role do |xml, role_type|
    xml.role(:type => role_type)
  end

  define_template :person do |xml|
    xml.person {
      xml.identifier(:type => 'sunetid')
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
      
  # Adding/removing nodes.

  def insert_role(role_type)
    return add_child_node(ng_xml.root, :role, role_type)
  end

  def insert_person(role_node)
    return add_child_node(role_node, :person)
  end

  def insert_group(role_node, group_type)
    return add_child_node(role_node, :group, group_type)
  end

  def remove_node(term, index)
    # Tests postponed until we know what this method should do. MH 7/3.
    node = self.find_by_terms(term.to_sym => index.to_i).first
    unless node.nil?
      node.remove
      self.dirty = true
    end
  end

end
