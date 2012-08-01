# A mixin for roleMetadata stuff.
module Hydrus::Responsible

  # Returns of hash of role info. Also see person_roles=
  def person_roles
    h = {}
    roleMetadata.find_by_terms(:role, :person, :identifier).each do |n|
      id   = n.text
      role = n.parent.parent[:type]
      h[role] ||= {}
      h[role][id] = true
    end
    return h
  end
  
  # Takes a hash of SUNETIDs and roles.
  # Rewrites roleMetadata to reflect the contents of the hash.
  # Example input: TODO (also see unit test).
  def person_roles= *args
    roleMetadata.remove_nodes(:role)
    h = args.first
    h.keys.sort { |a,b| a.to_i <=> b.to_i }.each { |k|
      id   = h[k]['id'].strip
      role = h[k]['role'].strip
      roleMetadata.add_person_with_role(id, role) unless id == ''
    }
  end

end
