class AdminController < ApplicationController

  before_filter :authenticate_user!

  # updating the users can only be an ajax call from an administrator
  def update_users
    return unless request.xhr? && Hydrus::Authorizable.can_act_as_administrator?(current_user)
        
    # admins=UserRole.find_by_role('administrators')
    # unless admins.blank?
    #   admins.users=params[:administrators]
    #   admins.save
    # end
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
    
    render 'update_users.js'
  end
end