module ApplicationHelper
  include HydrusFormHelper

  def application_name
    'Stanford Digital Repository'
  end

  def hydrus_format_date(input_string)
    input_string.blank? ? '' : input_string.to_date.strftime("%b %d, %Y")
  end

  def seen_beta_dialog?
    if session[:seen_beta_dialog]
      return true
    else
      session[:seen_beta_dialog]=true
      return false
    end
  end

  def collection_status(obj)
    obj.publish ? "open" : "closed"
  end

  def render_head_content
    render_extra_head_content + content_for(:head)
  end

  def hydrus_signin_link
    link_to("Sign in", new_user_session_path, :class=>'signin_link', :"data-url" => new_signin_path)
  end

  def hydrus_object_setting_value(obj)
    return (obj.blank? ? content_tag(:span, "not specified", :class => "unspecified") : obj)
  end

end
