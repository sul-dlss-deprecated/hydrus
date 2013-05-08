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

    @exception=exception
    @referer=request.referer
    
    unless Dor::Config.hydrus.exception_recipients.blank? || exception.message.strip == "Connection reset by peer" # connection reset by peer is coming from new relic
      HydrusMailer.error_notification(:exception=>@exception,:current_user=>current_user,:referer=>@referer).deliver 
    end
    
    if Dor::Config.hydrus.exception_error_page && !(exception.message.strip == "Connection reset by peer") # connection reset by peer is coming from new relic
        logger.error(@exception.message)
        logger.error(@exception.backtrace.join("\n"))
        render 'error', :status=>500
      else
        raise(@exception)
     end

  end

  def contact
    @page_title="Contact Us"
    @from=params[:from]
    @subject=params[:subject]
    @name=params[:name]
    @email=params[:email]
    @message=params[:message]
    
    if request.post?
      unless @message.blank?
        HydrusMailer.contact_message(:params=>params,:request=>request,:user=>current_user).deliver 
        flash[:notice]="Your message has been sent."
        @message=nil
        @name=nil
        @email=nil        
        unless @from.blank?
          redirect_to(@from)
          return
        end
      else
        flash.now[:error]="Please enter message text."
      end
    end
    render 'contact'
  end
  
  # Used to determine if we should show beta message in UI.
  def is_production?
    return (Rails.env.production? and (
      !request.env["HTTP_HOST"].nil? and
      !request.env["HTTP_HOST"].include?("-test") and
      !request.env["HTTP_HOST"].include?("-dev") and
      !request.env["HTTP_HOST"].include?("-stage")
    ))
  end

  # When on an item/collection page, check druid against object type
  # and redirect to correct controller if needed.
  def redirect_if_not_correct_object_type
    return unless @fobj
    ot = @fobj.object_type
    if %w(item collection).include?(ot)
      return if self.controller_name == "hydrus_#{ot}s"
      p = request.fullpath            # Eg: /items/druid:oo000oo0003/edit
      p = p.sub(/\A\/\w+/, "/#{ot}s") # Change 'item' to 'collection'.
      redirect_to(p)
    else
      # Don't think this will ever be reached.
      # Currently, exceptions occur if the PID is not a Hydrus Item or Collection.
      msg = "You do not have sufficient privileges to view the requested item."
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
