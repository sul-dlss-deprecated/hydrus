class Hydrus::RoleMetadataDS < ActiveFedora::OmDatastream

  include SolrDocHelper
  include Hydrus::GenericDS

  set_terminology do |t|

    t.root :path => 'roleMetadata'

    t.role do
      t.type_ :path => {:attribute => 'type'}
      t.person do
        t.identifier :index_as => [:facetable] do
          t.type_ :path => {:attribute => 'type'}
        end
        t.name
      end
      t.group do
        t.identifier :index_as => [:facetable]  do
          t.type_ :path => {:attribute => 'type'}
        end
      end
    end

    t.person_id :proxy => [:role, :person, :identifier]

    # Collection-level roles.
    t.collection_creator        :ref => [:role], :attributes => {:type => 'hydrus-collection-creator'}
    t.collection_manager        :ref => [:role], :attributes => {:type => 'hydrus-collection-manager'}
    t.collection_depositor      :ref => [:role], :attributes => {:type => 'hydrus-collection-depositor'}
    t.collection_item_depositor :ref => [:role], :attributes => {:type => 'hydrus-collection-item-depositor'}
    t.collection_reviewer       :ref => [:role], :attributes => {:type => 'hydrus-collection-reviewer'}
    t.collection_viewer         :ref => [:role], :attributes => {:type => 'hydrus-collection-viewer'}

    # Item-level roles.
    t.item_manager              :ref => [:role], :attributes => {:type => 'hydrus-item-manager'}
    t.item_depositor            :ref => [:role], :attributes => {:type => 'hydrus-item-depositor'}

    t.item_depositor_person_identifier(
      :ref => [:item_depositor, :person, :identifier],
      :index_as => [:facetable, :displayable]
    )
  end

  ####
  # Adding nodes.
  ####

  # Takes a SUNET ID and a role.
  # Adds the person under the given role.
  def add_person_with_role(sunetid, role_type)
    return insert_person(get_or_add_role_node(role_type), sunetid)
  end

  # Takes a workgroup name and a role.
  # Adds the group under the given role.
  def add_group_with_role(workgroup, role_type)
    return insert_group(get_or_add_role_node(role_type), workgroup)
  end

  # Takes a role name.
  # Returns the Nokogiri node corresponding to that role.
  # Creates the node if it does not exist already.
  def get_or_add_role_node(role_type)
    nodes = find_by_xpath("/roleMetadata/role[@type='#{role_type}']")
    return nodes.size == 0 ? insert_role(role_type) : nodes.first
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

  def insert_group(role_node, workgroup)
    add_hydrus_child_node(role_node, :group, workgroup)
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

  define_template :group do |xml, workgroup|
    xml.group {
      xml.identifier(:type => 'workgroup') { xml.text(workgroup) }
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

  def to_solr(solr_doc = {}, *args)
    super(solr_doc, *args)
    # Get the roles and their persons.
    h = Hydrus::Responsible.person_roles(self)
    # Add keys to the solr index to aggregate the roles of each user.
    h.each do |role, ids|
      ids.each do |id|
        add_solr_value(solr_doc, "roles_of_sunetid_#{id}", role, :string, [:searchable])
      end
    end
    # Return the solr doc.
    return solr_doc
  end

end
