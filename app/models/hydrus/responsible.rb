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
  def person_roles
    h = {}
    roleMetadata.find_by_terms(:role, :person, :identifier).each do |n|
      id   = n.text
      role = n.parent.parent[:type]
      h[role] ||= Set.new
      h[role] << id
    end
    return h
  end

  # Takes a hash of roles and SUNETIDs.
  #   {
  #     'hydrus-collection-manager'        => 'willy,naomi',
  #     'hydrus-collection-item-depositor' => 'hindman,cbeer',
  #     etc.
  #   }
  # Rewrites roleMetadata <person> nodes to reflect the contents of the hash.
  def person_roles=(h)
    roleMetadata.remove_nodes(:role, :person)
    h.each do |role, ids|
      parse_delimited(ids).each do |id|
        roleMetadata.add_person_with_role(id, role)
      end
    end
  end

end
