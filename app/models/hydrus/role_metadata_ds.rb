class Hydrus::RoleMetadataDS < ActiveFedora::NokogiriDatastream

  include SolrDocHelper
  include Hydrus::GenericDS
  
  set_terminology do |t|

    t.root :path => 'roleMetadata'

    t.role do
      t.type_ :path => {:attribute => 'type'}
      t.person do
        t.identifier do
          t.type_ :path => {:attribute => 'type'}
        end
        t.name
      end
    end
    
    t.person_id :proxy => [:role, :person, :identifier]

    t.collection_creator   :ref => [:role], :attributes => {:type => 'hydrus-collection-creator'}
    t.collection_manager   :ref => [:role], :attributes => {:type => 'hydrus-collection-manager'}
    t.collection_depositor :ref => [:role], :attributes => {:type => 'hydrus-collection-depositor'}
    t.collection_reviewer  :ref => [:role], :attributes => {:type => 'hydrus-collection-reviewer'}
    t.collection_viewer    :ref => [:role], :attributes => {:type => 'hydrus-collection-viewer'}
    t.item_manager         :ref => [:role], :attributes => {:type => 'hydrus-item-manager'}
    t.item_depositor       :ref => [:role], :attributes => {:type => 'hydrus-item-depositor'}

  end

  ####
  # Adding nodes.
  ####

  # Takes a SUNET ID and a role.
  # Adds the person under the given role. Will spawn a new role node,
  # if the role isn't already present.
  def add_person_with_role(id, role_type)
    role_node = find_by_xpath("/roleMetadata/role[@type='#{role_type}']")
    if role_node.size == 0
      new_role_node = insert_role(role_type)
      return insert_person(new_role_node, id)
    else
      return insert_person(role_node, id)
    end
  end  

  def add_empty_person_to_role(role_type)
    add_person_with_role("", role_type)
  end  

  def insert_role(role_type)
    add_hydrus_child_node(ng_xml.root, :role, role_type)
  end

  def insert_person(role_node, sunetid)
    add_hydrus_child_node(role_node, :person, sunetid)
  end

  ####
  # OM templates.
  ####

  define_template :role do |xml, role_type|
    xml.role(:type => role_type)
  end

  define_template :person do |xml, sunetid|
    xml.person {
      xml.identifier(:type => 'sunetid') { xml.text(sunetid) }
      xml.name
    }
  end

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.roleMetadata
    end.doc
  end

  ####
  # Other.
  ####

  # Takes a string       (eg, hydrus-item-foo or hydrus_collection_bar)
  # Returns a new string (eg, hydrus_item_foo or hydrus-collection-bar).
  # Was used in our old implementation. Might not be needed in future.
  TOGGLE_HYPHEN_REGEX = / \A (hydrus) ([_\-]) (collection|item) \2 ([a-z]) /ix
  def toggle_hyphen_underscore(role_type)
    role_type.sub(TOGGLE_HYPHEN_REGEX) {
      [$1, $3, $4].join($2 == '_' ? '-' : '_')
    }
  end

  def to_solr(solr_doc = {}, *args)
    super(solr_doc, *args)
    # Get the roles and their persons. This duplicates code in Hydrus::Responsible.
    h = {}
    find_by_terms(:role, :person, :identifier).each do |n|
      id   = n.text
      role = n.parent.parent[:type]
      h[role] ||= []
      h[role] << id
    end
    h.values.each { |ids| ids.uniq! }
    # Add keys to the solr index to aggregate the roles of each user.
    h.each do |role, ids|
      ids.each do |id|
        add_solr_value(
          solr_doc, "roles_of_sunetid_#{id}", role,
          :string, [:searchable]
        )
      end
    end
    # Return the solr doc.
    return solr_doc
  end

end
