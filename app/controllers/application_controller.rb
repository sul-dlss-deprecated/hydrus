class ApplicationController < ActionController::Base
  include Blacklight::Controller  
  include Hydra::Controller
  include Hydrus::RoutingHacks

  helper Hydrus::RoutingHacks

  def layout_name
   'hydra-head'
  end

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery
end
