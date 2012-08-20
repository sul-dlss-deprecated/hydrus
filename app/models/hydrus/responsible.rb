# A mixin for roleMetadata stuff.
module Hydrus::Responsible

  # Returns an array of SUNet IDs having the given role.
  def persons_with_role(role)
    q = "//role[@type='#{role}']/person/identifier"
    return roleMetadata.find_by_xpath(q).map { |node| node.text }
  end

  # Returns of hash of role info.
  #   {
  #     'hydrus-collection-manager' => ['willy',   'naomi'],
  #     'hydrus-item-depositor'     => ['hindman', 'cbeer'],
  #     etc.
  #   }
  def person_roles
    h = {}
    roleMetadata.find_by_terms(:role, :person, :identifier).each do |n|
      id   = n.text
      role = n.parent.parent[:type]
      h[role] ||= []
      h[role] << id
    end
    h.values.each { |ids| ids.uniq! }
    return h
  end

  # Takes a hash of roles and SUNETIDs.
  #   {
  #     'hydrus-collection-manager' => 'willy,naomi',
  #     'hydrus-item-depositor'     => 'hindman,cbeer',
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
