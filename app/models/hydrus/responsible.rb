# frozen_string_literal: true

# A mixin for roleMetadata stuff.

module Hydrus::Responsible

  # Returns a set of SUNet IDs having the given role.
  def persons_with_role(role)
    q     = "//role[@type='#{role}']/person/identifier"
    roles = roleMetadata.find_by_xpath(q).map { |node| node.text }
    Set.new(roles)
  end

  # Returns a set of roles for the given SUNet ID.
  def roles_of_person(person_id)
    roles = Set.new
    person_roles.each do |role, ids|
      roles << role if ids.include?(person_id)
    end
    roles
  end

  # Returns of hash-of-sets containing role info.
  #   {
  #     'hydrus-collection-manager'        => <'willy',   'naomi'>,
  #     'hydrus-collection-item-depositor' => <'hindman', 'cbeer'>,
  #     etc.
  #   }
  #
  # The implementation occurs in the module method, because we also
  # need to invoke the same logic from roleMetadataDS. Probably
  # could use some class/module redesign here.
  def person_roles
    Hydrus::Responsible.person_roles(roleMetadata)
  end

  def self.person_roles(ds)
    h = {}
    ds.find_by_terms(:role, :person, :identifier).each do |n|
      id   = n.text
      role = n.parent.parent[:type]
      h[role] ||= Set.new
      h[role] << id
    end
    h
  end

  # Takes a hash of roles and SUNETIDs: see pruned_role_info().
  # Rewrites roleMetadata <person> nodes to reflect the contents of the hash.
  def person_roles=(h)
    roleMetadata.remove_nodes(:role, :person)
    Hydrus::Responsible.pruned_role_info(h).each do |id, roles|
      roles.each do |r|
        roleMetadata.add_person_with_role(id, r)
      end
    end
  end
  #Takes a sunetid and an apo pid
  #use solr to quickly find the roles for a person under a given apo
  def self.roles_of_person person_id, apo_id
    toret=[]
    roles=role_labels(:collection_level)
    h = Hydrus::SolrQueryable.default_query_params
    #query by id
    h[:q]="id:\"#{apo_id}\""
    #this is lazy, should just be the fields from roles modified to match convention
    h[:fl]='*'
    resp, sdocs = Hydrus::SolrQueryable.issue_solr_query(h)
    #only 1 doc
    doc=resp.docs.first
    roles.keys.each do |key|
      #the solr field is based on the role name, but doesnt match it precisely
      field_name=key.gsub('hydrus-','').gsub('-','_')+'_person_identifier_t'
      if doc[field_name] && doc[field_name].include?(person_id)
        toret << roles[key][:label]
      end
    end
    toret
  end
  
  # Takes a hash of roles and SUNETIDs:
  #
  #   {
  #     'hydrus-collection-manager'        => 'willy,naomi',
  #     'hydrus-collection-item-depositor' => 'hindman,cbeer',
  #     etc.
  #   }
  #
  # Returns a hash of sets:
  #
  #   {
  #     'willy'   => { PRUNED SET OF ROLES FOR willy },
  #     'hindman' => { PRUNED SET OF ROLES FOR hindman },
  #     etc.
  #   }
  #
  # The sets are pruned to exclude lesser (implied) roles. For example, if
  # FOO is a collection manager, there is no need to designate FOO as
  # a collection viewer.
  def self.pruned_role_info(h)
    # Parse the input hash and create the new hash.
    proles = {}
    h.each do |role, ids|
      Hydrus::ModelHelper.parse_delimited(ids).each do |id|
        proles[id] ||= Set.new
        proles[id] << role
      end
    end
    # Prune the new hash of lesser roles.
    lesser = role_labels(:only_lesser)
    proles.each do |id, roles|
      lesser.each do |rbig, rsmalls|
        rsmalls.each { |r| roles.delete(r) } if roles.include?(rbig)
      end
    end
    proles
  end

  # By default, returns a hash-of-hashes of roles and their UI labels and help texts.
  # The user can supply the following values in the options list:
  #   :collection_level   Prune the item-level roles from the hash.
  #   :only_labels        Return a simple hash of just labels.
  #   :only_help          "                            help texts.
  #   :only_lesser        "                            less powerful (implied) roles.
  #
  # NOTE: although collection-manager might be viewed as a role implied
  # by collection-depositor, we have decided not to prune the manager role
  # from depositors.
  def self.role_labels(*opts)
    # The data.
    h = {
      # Item-level roles.
      'hydrus-item-depositor' => {
        label: 'Item Depositor',
        help: 'This is the original depositor of the item and can peform any action with the item',
        lesser: %w(hydrus-item-manager),
      },
      'hydrus-item-manager' => {
        label: 'Item Manager',
        help: 'These users can edit the item',
        lesser: %w(),
      },
      # Collection-level roles.
      'hydrus-collection-depositor' => {
        label: 'Owner',
        help: 'This user is the collection owner and can perform any action with the collection',
        lesser: %w(hydrus-collection-reviewer hydrus-collection-item-depositor hydrus-collection-viewer),
      },
      'hydrus-collection-manager' => {
        label: 'Manager',
        help: 'These users can edit collection details, and add and review items in the collection',
        lesser: %w(hydrus-collection-reviewer hydrus-collection-item-depositor hydrus-collection-viewer),
      },
      'hydrus-collection-reviewer' => {
        label: 'Reviewer',
        help: 'These users can review items in the collection, but not add new items',
        lesser: %w(hydrus-collection-viewer),
      },
      'hydrus-collection-item-depositor' => {
        label: 'Depositor',
        help: 'These users can add items to the collection, but cannot act as reviewers',
        lesser: %w(hydrus-collection-viewer),
      },
      'hydrus-collection-viewer' => {
        label: 'Viewer',
        help: 'These users can view items in the collection only',
        lesser: %w(),
      },
    }
    # Remove item-level roles.
    if opts.include?(:collection_level)
      h.delete('hydrus-item-depositor')
      h.delete('hydrus-item-manager')
    end
    # Convert to a simple hash of just labels or just help.
    k = opts.include?(:only_labels) ? :label  :
        opts.include?(:only_help)   ? :help   :
        opts.include?(:only_lesser) ? :lesser : nil
    h.keys.each { |role| h[role] = h[role][k] } if k
    # Return hash.
    h
  end

  def self.roles_for_ui(roles)
    labels = role_labels(:only_labels)
    roles.map { |r| labels[r] }
  end

end
