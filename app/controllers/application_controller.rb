class ApplicationController < ActionController::Base

  include SulChrome::Controller
  include Blacklight::Controller  
  include Hydra::Controller::ControllerBehavior
  helper_method :is_production?
  
  def layout_name
   'sul_chrome/application'
  end
  
  # used to determine if we should show beta message in UI
  def is_production?
    return (Rails.env.production? and (
      !request.env["HTTP_HOST"].nil? and
      !request.env["HTTP_HOST"].include?("-test") and
      !request.env["HTTP_HOST"].include?("-dev") and
      !request.env["HTTP_HOST"].include?("localhost")
    ))
  end

  # Registers an object in Dor, and returns it.
  # TODO: move to GenericObject as a class method.
  def register_dor_object(*args)
    return Dor::RegistrationService.register_object dor_registration_params(*args)
  end

  private

  # Returns a hash of info needed to register a Dor object.
  # TODO: move to GenericObject as a class method.
  def dor_registration_params(user_string, object_type, apo_pid)
    return {
      :object_type  => object_type,
      :admin_policy => apo_pid,
      :source_id    => { "Hydrus" => "#{object_type}-#{user_string}-#{Time.now}" },
      :label        => "Hydrus",
      :tags         => ["Project : Hydrus"]
    }
  end

  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  protect_from_forgery

end
