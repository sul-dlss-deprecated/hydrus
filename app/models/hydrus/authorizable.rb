# See get_fedora_object() in ability.rb for discussion
# of the nil checks in this module.

module Hydrus::Authorizable

  ####
  # Legacy logic to get SUNET IDs of those with Hydrus-wide powers from database.
  # This is now managed by LDAP groups.
  ####

  def self.administrators
    get_users_in_role('administrators')
  end

  def self.collection_creators
    return administrators.union(get_users_in_role('collection_creators'))
  end

  def self.global_viewers
    return administrators.union(get_users_in_role('global_viewers'))
  end

  def self.get_users_in_role(role)
    users_in_role=UserRole.find_by_role(role)
    return users_in_role.blank? ? Set.new([]) : Set.new(users_in_role.users.delete(' ').split(','))
  end
  
  ####
  # Roles.
  ####

  def self.collection_editor_roles
    return Set.new %w(
      hydrus-collection-manager
      hydrus-collection-depositor
    )
  end

  def self.item_creator_roles
    return Set.new %w(
      hydrus-collection-manager
      hydrus-collection-depositor
      hydrus-collection-item-depositor
    )
  end

  def self.item_editor_roles
    return Set.new %w(
      hydrus-collection-manager
      hydrus-collection-depositor
      hydrus-item-depositor
      hydrus-item-manager
    )
  end

  def self.item_reviewer_roles
    return Set.new %w(
      hydrus-collection-reviewer
    )
  end

  ####
  # Utility methods and Hydrus-wide abilities.
  ####

  # Takes two Sets.
  # Returns true if they have any items in common.
  def self.does_intersect(s1, s2)
    return s1.intersection(s2).size > 0
  end

  # Returns true if the given user is a Hydrus administrator.
  def self.is_administrator(user)
    return user.is_administrator? || administrators.include?(user.sunetid)
  end

  # Returns true if the given user is a Hydrus-wide viewer.
  def self.is_global_viewer(user)
    return user.is_global_viewer? || global_viewers.include?(user.sunetid)
  end

  # Returns true if the given user can act as a Hydrus administrator,
  # either by being one or because we're running in development mode.
  def self.can_act_as_administrator(user)
    return (is_administrator(user) or Rails.env == 'development')
  end

  # Returns true if the given user can create new Hydrus Collections.
  def self.can_create_collections(user)
    return user.is_collection_creator? || collection_creators.include?(user.sunetid)
  end

  ####
  # General-purpose dispatching methods.
  ####

  # Takes a verb (read or edit), user, and object.
  # Dispatches to the appropriate can_* method.
  def self.can_do_it(verb, user, obj)
    return false if obj.nil?
    c = obj.hydrus_class_to_s.downcase # 'collection' or 'item' or 'apo'
    return send("can_#{verb}_#{c}", user, obj)
  end

  # Takes a user and a Collection or Item.
  # Returns true if the user can read the object.
  def self.can_read_object(user, obj)
    return can_do_it('read', user, obj)
  end

  # Takes a user and a Collection or Item.
  # Returns true if the user can edit the object.
  def self.can_edit_object(user, obj)
    return can_do_it('edit', user, obj)
  end

  ####
  # Particular abilities.
  ####

  # Returns true if the given user can view the given APO.
  def self.can_read_apo(user, apo)
    return can_act_as_administrator(user)
  end

  # Returns true if the given user can view the given Collection.
  def self.can_read_collection(user, coll)
    return true if is_global_viewer(user)
    user_roles = coll.roles_of_person(user.sunetid)
    return user_roles.size > 0
  end

  # Returns true if the given user can view the given Item.
  def self.can_read_item(user, item)
    return true if is_global_viewer(user)
    sid = user.sunetid
    user_roles = item.roles_of_person(sid) + item.apo.roles_of_person(sid)
    return user_roles.size > 0
  end

  # Returns true if the given user can create new Items
  # in the given Collection.
  def self.can_create_items_in(user, coll)
    return false if coll.nil?
    return true if is_administrator(user)
    user_roles = coll.roles_of_person(user.sunetid)
    return does_intersect(user_roles, item_creator_roles)
  end

  # Returns true if the given user can edit the given Collection.
  def self.can_edit_collection(user, coll)
    return true if is_administrator(user)
    user_roles = coll.roles_of_person(user.sunetid)
    return does_intersect(user_roles, collection_editor_roles)
  end

  # Returns true if the given user can edit the given Item.
  def self.can_edit_item(user, item)
    sid = user.sunetid
    return true if is_administrator(user)
    user_roles = item.roles_of_person(sid) + item.apo.roles_of_person(sid)
    return does_intersect(user_roles, item_editor_roles)
  end

  # Returns true if the given user can review the given Item.
  def self.can_review_item(user, item)
    return true if can_edit_collection(user, item.collection)
    user_roles = item.apo.roles_of_person(user.sunetid)
    return does_intersect(user_roles, item_reviewer_roles)
  end

end
