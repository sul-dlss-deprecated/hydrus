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

  # def ap_dump(*args)
  #   header = '=' * 80
  #   puts header, args.ai, header
  # end
  # helper_method :ap_dump

  protect_from_forgery
end
