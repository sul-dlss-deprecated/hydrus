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

  def delete_object(pid)
    obj=Hydrus::GenericObject.find(pid)
    Dor::Config.fedora.client["objects/#{pid}"].delete
    Dor::SearchService.solr.delete_by_id(pid)  
    #TODO delete from our local solr too!
    parent_object_directory=File.join(obj.base_file_directory,'..')
    FileUtils.rm_rf(parent_object_directory) if File.directory?(parent_object_directory)
  end
  
  def exception_on_website(exception)
    
    @exception=exception
    
    HydrusMailer.error_notification(:exception=>@exception,:current_user=>current_user).deliver unless Dor::Config.hydrus.exception_recipients.blank? 
    
    if Dor::Config.hydrus.exception_error_page 
        logger.error(@exception.message)
        logger.error(@exception.backtrace.join("\n"))
        render 'signin/error'
      else
        raise(@exception)
     end

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

  # Take a Collection or Item.
  # Using the objection's validation errors, builds an HTML-ready 
  # string for display in a flash message.
  def errors_for_display(obj)
    es = obj.errors.messages.map { |field, error|
      "#{field.to_s.humanize.capitalize} #{error.join(', ')}."
    }
    return es.join("<br/>").html_safe
  end

  # Take a Collection/Item and a message.
  # Tries to save the object.
  # Returns the value of that save() call, and also sets
  # the appropriate flash message.
  def try_to_save(obj, success_msg)
    v = obj.save
    if v
      flash[:notice] = success_msg
    else
      flash[:error] = errors_for_display(obj)
    end
    return v
  end

end
