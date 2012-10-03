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

  # By default, returns a hash-of-hashes of roles and their UI labels and help texts.
  # The user can supply the following values in the options list:
  #   :collection_level   Prune the item-level roles from the hash.
  #   :only_labels        Return a simple hash of just labels. Trumps :only_help.
  #   :only_help          Return a simple hash of just help texts.
  def self.role_labels(*opts)
    # The data.
    h = {
      # Item-level roles.
      'hydrus-item-depositor' => {
        :label      => "Item Depositor",
        :help       => "This is the original depositor of the item and can peform any action with the item",
      },
      'hydrus-item-manager' => {
        :label      => "Item Manager",
        :help       => "These users can edit the item",
      },
      # Collection-level roles.
      'hydrus-collection-depositor' => {
        :label => "Owner",
        :help  => "This user is the collection owner and can perform any action with the collection",
      },
      'hydrus-collection-manager' => {
        :label => "Manager",
        :help  => "These users can edit collection details, and add and review items in the collection",
      },
      'hydrus-collection-reviewer' => {
        :label => "Reviewer",
        :help  => "These users can review items in the collection, but not add new items",
      },
      'hydrus-collection-item-depositor' => {
        :label => "Depositor",
        :help  => "These users can add items to the collection, but cannot act as reviewers",
      },
      'hydrus-collection-viewer' => {
        :label => "Viewer",
        :help  => "These users can view items in the collection only",
      },
    }
    # Remove item-level roles.
    if opts.include?(:collection_level)
      h.delete('hydrus-item-depositor')
      h.delete('hydrus-item-manager')
    end
    # Convert to a simple hash of just labels or just help.
    k = opts.include?(:only_labels) ? :label :
        opts.include?(:only_help)   ? :help  : nil
    h.keys.each { |role| h[role] = h[role][k] } if k
    # Return hash.
    return h
  end

  def self.roles_for_ui(roles)
    labels = role_labels(:only_labels)
    return roles.map { |r| labels[r] }
  end

end
