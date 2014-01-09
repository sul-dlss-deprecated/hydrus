class AdminController < ApplicationController

  before_filter :authenticate_user!
  skip_authorization_check :only => [:update_users] # we check if they are admins in the action itself

  # updating the users can only be an ajax call from an administrator
  def update_users
    unless request.xhr? && Hydrus::Authorizable.can_act_as_administrator(current_user)
      return 
    else      
      collection_creators=UserRole.find_by_role('collection_creators')
      unless collection_creators.blank?
        collection_creators.users=params[:collection_creators]
        collection_creators.save
      end
      global_viewers=UserRole.find_by_role('global_viewers')
      unless global_viewers.blank?
        global_viewers.users=params[:global_viewers]
        global_viewers.save
      end
    end
  end

end