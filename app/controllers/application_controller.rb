class ApplicationController < ActionController::Base
  include SulChrome::Controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include Hydrus::ModelHelper
  include ActionView::Helpers::OutputSafetyHelper # for safe_join() and raw()

  check_authorization unless: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  helper_method :to_bool
  helper_method :current_user

  # This is a backport from Rails 5 and can be removed when we use Rails 5
  def redirect_back(fallback_location:, **args)
    if referer == request.headers['Referer']
      redirect_to referer, **args
    else
      redirect_to fallback_location, **args
    end
  end

  def layout_name
    'sul_chrome/application'
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
      msg = 'You do not have sufficient privileges to view the requested item.'
      flash[:error] = msg
      redirect_to root_url
    end
  end

  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery

  protected

  def current_user
    super.tap do |cur_user|
      break unless cur_user
      if request.env['eduPersonEntitlement']
        cur_user.groups = request.env['eduPersonEntitlement'].split(';')
      end
    end
  end

  # Take a Collection or Item.
  # Using the objection's validation errors, builds an HTML-ready
  # string for display in a flash message.
  def errors_for_display(obj)
    es = obj.errors.messages.map { |field, error|
      "#{field.to_s.humanize.capitalize} #{error.join(', ')}."
    }
    safe_join(es, raw('<br />'))
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
    v
  end
end
