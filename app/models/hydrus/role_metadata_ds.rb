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
    
    t.manager    :ref => [:role], :attributes => {:type => 'manager'}
    t.depositor  :ref => [:role], :attributes => {:type => 'depositor'}
    t.reviewer   :ref => [:role], :attributes => {:type => 'reviewer'}
    t.viewer     :ref => [:role], :attributes => {:type => 'viewer'}
  end

  def to_solr(solr_doc=Hash.new, *args)
    self.find_by_xpath('/roleMetadata/role/*').each do |actor|
      role_type = actor.parent['type']
      val = [actor.at_xpath('identifier/@type'),actor.at_xpath('identifier/text()')].join ':'
      add_solr_value(solr_doc, "apo_role_#{actor.name}_#{role_type}", val, :string, [:searchable, :facetable])
      add_solr_value(solr_doc, "apo_role_#{role_type}", val, :string, [:searchable, :facetable])
      if ['manager','depositor'].include? role_type
        add_solr_value(solr_doc, "apo_register_permissions", val, :string, [:searchable, :facetable])
      end
    end
    solr_doc
  end

  # Blocks to pass into Nokogiri::XML::Builder.new()

  define_template :role do |xml|
    xml.role
  end

  define_template :person do |xml|
    xml.person {
      xml.identifier(:type => 'sunetid')
      xml.name
    }
  end

  define_template :group do |xml|
    xml.group {
      xml.identifier
      xml.name
    }
  end

  # Methods returning empty XML documents and nodes.

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.roleMetadata
    end.doc
  end
      
  def insert_role
    return add_child_node(ng_xml.root, :role)
  end

  def insert_person(role_node)
    return add_child_node(role_node, :person)
  end

  def insert_group(role_node)
    return add_child_node(role_node, :group)
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
