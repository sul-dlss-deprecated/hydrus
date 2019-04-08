class UserRole < ActiveRecord::Base
  # this table defines who is an adminstrator, global view and collection creator
  # TODO get rid of this and use LDAP groups instead
  # attr_accessible :role, :users
end
