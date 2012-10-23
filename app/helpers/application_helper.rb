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
      license_code
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

  # indicates if we should show the item edit tab for a given item
  # only if its not published yet, unless we are in development mode (to make development easier)
  def show_item_edit(item)
    can?(:edit,item) && (!item.is_published || ["development","test"].include?(Rails.env))
  end
  
  def edit_item_text(item)
    "Edit Draft"
  end
  
  # text to show on item view tab
  def view_item_text(item)
    item.is_published ? "Published Version" : "View Draft"
  end
  
  def hydrus_object_setting_value(obj)
    hydrus_is_empty?(obj) ? content_tag(:span, "not specified", :class => "unspecified") : obj
  end

  # a helper to create links to items that may or may not have titles yet
  def item_title_link(item)
    title_text=item.title.blank? ? 'new item' : item.title
    return link_to(title_text, polymorphic_path(item))
  end
  
  # Take a datetime string.
  # Returns a string using the default Hydrus date format.
  def formatted_datetime(datetime, k = :datetime)
    begin
      return Time.parse(datetime.to_s).strftime(datetime_format(k))
    rescue
      return nil
    end
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
  
  def datetime_format(k)
    return (k == :date ? '%d-%b-%Y' :
            k == :time ? '%I:%M %P' : '%d-%b-%Y %I:%M %P')
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
