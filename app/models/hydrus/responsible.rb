# A mixin for roleMetadata stuff.

module Hydrus::Responsible

  # Returns a set of SUNet IDs having the given role.
  def persons_with_role(role)
    q     = "//role[@type='#{role}']/person/identifier"
    roles = roleMetadata.find_by_xpath(q).map { |node| node.text }
    return Set.new(roles)
  end

  # Returns a set of roles for the given SUNet ID.
  def roles_of_person(person_id)
    roles = Set.new
    person_roles.each do |role, ids|
      roles << role if ids.include?(person_id)
    end
    return roles
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
    return Hydrus::Responsible.person_roles(roleMetadata)
  end

  def self.person_roles(ds)
    h = {}
    ds.find_by_terms(:role, :person, :identifier).each do |n|
      id   = n.text
      role = n.parent.parent[:type]
      h[role] ||= Set.new
      h[role] << id
    end
    return h
  end

  # Takes a hash of roles and SUNETIDs: see pruned_role_info().
  # Rewrites roleMetadata <person> nodes to reflect the contents of the hash.
  def person_roles=(h)
    roleMetadata.remove_nodes(:role, :person)
    Hydrus::Responsible.pruned_role_info(h).each do |role, ids|
      ids.each do |id|
        roleMetadata.add_person_with_role(id, role)
      end
    end
  end
  #Takes a sunetid and an apo pid
  #use solr to quickly find the roles for a person under a given apo
  def self.roles_of_person person_id, apo_id
    toret=[]
    roles=Hydrus.role_labels(:collection_level)
    h           = Hydrus::SolrQueryable.default_query_params
    #query by id
    h[:q]="id:\"#{apo_id}\""
    #this is lazy, should just be the fields from roles modified to match convention
    h[:fl]='*'
    resp, sdocs = Hydrus::SolrQueryable.issue_solr_query(h)
    #only 1 doc
    doc=resp.docs.first
    roles.keys.each do |key|
      #the solr field is based on the role name, but doesnt match it precisely
      field_name=Solrizer.solr_name(key.gsub('hydrus-','').gsub('-','_')+'_person_identifier', :facetable)
      if doc[field_name] && doc[field_name].include?(person_id)
        toret << roles[key][:label]
      end
    end
    return toret
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
      ids = Hydrus::ModelHelper.parse_delimited(ids) if ids.is_a? String

      ids.each do |id|
        proles[id] ||= Set.new
        proles[id] << role
      end
    end
    # Prune the new hash of lesser roles.
    lesser = Hydrus.role_labels(:only_lesser)
    proles.each do |id, roles|
      lesser.each do |rbig, rsmalls|
        rsmalls.each { |r| roles.delete(r) } if roles.include?(rbig)
      end
    end

    role_info = {}

    proles.each do |id, roles|
      roles.each do |r|
        role_info[r] ||= []
        role_info[r] << id
      end
    end

    return role_info
  end

end
