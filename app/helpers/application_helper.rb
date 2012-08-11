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

  def render_head_content
    render_extra_head_content + content_for(:head)
  end

  def hydrus_signin_link
    link_to("Sign in", new_signin_path(:referrer => request.fullpath), :class=>'signin_link', :"data-url" => new_signin_path(:referrer => request.fullpath))
  end
  
  def hydrus_strip(value)
    value.nil? ? "" : value.strip
  end
  
  def hydrus_object_setting_value(obj)
    hydrus_is_empty?(obj) ? content_tag(:span, "not specified", :class => "unspecified") : obj
  end

  # Take a datetime string.
  # Returns a string using the default Hydrus date format.
  def formatted_datetime(datetime, k = :datetime)
    begin
      return Time.parse(datetime).strftime(datetime_format(k))
    rescue
      return nil
    end
  end

  def datetime_format(k)
    return (k == :date ? '%d-%b-%Y' :
            k == :time ? '%I:%M %P' : '%d-%b-%Y %I:%M %P')
  end

end
