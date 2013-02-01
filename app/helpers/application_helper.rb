module ApplicationHelper
  include HydrusFormHelper

  def application_name
    'Stanford Digital Repository'
  end

  def license_image(license_code)
    if Hydrus::GenericObject.license_type(license_code) == 'creativeCommons'
      image_tag "licenses/" + license_code.downcase.gsub('-','_') + ".png"
    end
  end

  def license_link(license_code)
    license_name=Hydrus::GenericObject.license_human(license_code)
    license_type=Hydrus::GenericObject.license_type(license_code)
    if license_type == 'creativeCommons'
      link_to license_name,'http://creativecommons.org/licenses/'
    elsif license_type == 'openDataCommons'
      link_to license_name,'http://opendatacommons.org/licenses/'
    else
      license_name
    end
  end

  def button_color(status)
    case status.downcase
      when "published"
        "success"
      else
        "warning"
      end
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

  def render_contextual_layout
    controller.controller_name == 'catalog' || controller.controller_name == 'sessions' ? (render "shared/home_contents") : (render "shared/main_contents")
  end

  def hydrus_signin_link
    link_to("Sign in", new_signin_path(:referrer => request.fullpath), :class=>'signin_link', :"data-url" => new_signin_path(:referrer => request.fullpath))
  end

  def terms_of_deposit_path(pid)
    url_for(:controller=>'hydrus_items',:action=>'terms_of_deposit',:pid=>pid)
  end

  def terms_of_deposit_agree_path(pid)
    url_for(:controller=>'hydrus_items',:action=>'agree_to_terms_of_deposit',:pid=>pid)
  end

  def hydrus_strip(value)
    value.nil? ? "" : value.strip
  end

  # Returns true if the Edit tab should be shown for the Collection or Item.
  #   - User can edit the object.
  #   - Object is not published.
  def show_item_edit(item)
    return false unless can?(:edit, item)
    return ! item.is_published
  end

  def edit_item_text(item)
    "Edit Draft"
  end

  # text to show on item view tab
  def view_item_text(item)
    item.is_published ? "Published Version" : "View Draft"
  end

  def hydrus_object_setting_value(obj)
    hydrus_is_empty?(obj) ? content_tag(:span, "to be entered", :class => "unspecified") : obj
  end

  # Takes a string. Escapes any HTML characters, converts
  # newlines to <br> tags, and then declars the string to be
  # safe for direct display as HTML.
  def show_line_breaks(txt)
    return html_escape(txt).gsub(/\r\n?|\n/, '<br/>').html_safe
  end

  def title_text(obj)
    obj.title.blank? ? "Untitled" : obj.title
  end

  # a helper to create links to items that may or may not have titles yet
  def title_link(obj)
    return link_to(title_text(obj), polymorphic_path(obj))
  end

  # this checks to see if the object passed in is "empty", which could be nil, a blank string, an array of strings with all elements that are blank,
  # an arbitrary object whose attributes are all blank, or an array of arbitrary objects whose attributes are all blank
  def hydrus_is_empty?(obj)
    if obj.nil? # nil case
      is_blank=true
    elsif obj.class == Array # arrays
      is_blank=obj.all? {|element| hydrus_is_empty?(element)}
    elsif obj.class == String # strings
      is_blank=obj.blank?
    else # case of abitrary object
      is_blank=hydrus_is_object_empty?(obj)
    end
    return is_blank
   end

  # this checks to see if the object passed in has attributes that are all blank
  def hydrus_is_object_empty?(obj)
    !get_attributes(obj).collect{|attribute| obj.send(attribute).blank?}.include?(false)
  end

  # this returns an array of the attributes that have setter methods on any arbitrary object (stripping out attribures you don't want), "=" stripped out as well
  def get_attributes(obj)
    obj.methods.grep(/\w=$/).collect{|method| method.to_s.gsub('=','')}-['validation_context','_validate_callbacks','_validators']
  end

  def render_contextual_navigation(model)
    render :partial=>"#{view_path_from_model(model)}/navigation"
  end

  def view_path_from_model(model)
    model.class.to_s.pluralize.parameterize("_")
  end

  def select_status_checkbox_icon(field)
    content_tag(:i, nil, :class =>  field ? "icon-check" : "icon-minus")
  end
end
