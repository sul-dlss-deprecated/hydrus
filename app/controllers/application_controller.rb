class ApplicationController < ActionController::Base
  include SulChrome::Controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include Hydrus::ModelHelper

  helper_method :to_bool
  helper_method :is_production?, :current_user

  rescue_from Exception, :with=>:exception_on_website

  def layout_name
   'sul_chrome/application'
  end

  def exception_on_website(exception)
    # TODO also log this exception in some special way and notify someone?
    is_production? ? redirect_to(error_url) : raise(exception)
  end

  # Used to determine if we should show beta message in UI.
  def is_production?
    return (Rails.env.production? and (
      !request.env["HTTP_HOST"].nil? and
      !request.env["HTTP_HOST"].include?("-test") and
      !request.env["HTTP_HOST"].include?("-dev") and
      !request.env["HTTP_HOST"].include?("localhost")
    ))
  end

  # When on an item/collection page, check druid against object type
  # and redirect to correct controller if needed.
  def redirect_if_not_correct_object_type
    return unless @document_fedora
    if !self.controller_name.include?(@document_fedora.object_type) && @document_fedora.object_type!='adminPolicy'
      redirect_url=Rails.application.routes.url_helpers.send("hydrus_#{@document_fedora.object_type}_path",@document_fedora.pid)
      redirect_to redirect_url
    elsif @document_fedora.object_type=='adminPolicy'
      msg  = "You do not have sufficient privileges to view the requested item."
      flash[:error] = msg
      redirect_to root_url
    end
  end

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery

  protected

  def current_user
    if request.env["WEBAUTH_USER"]
      current_user = WebAuthUser.new(request.env["WEBAUTH_USER"])
    else
      return super
    end
  end

end
