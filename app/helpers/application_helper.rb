# frozen_string_literal: true

module ApplicationHelper

  include HydrusFormHelper

  def application_name
    'Stanford Digital Repository'
  end

  def sidebar_items
    @sidebar_items ||= []
  end

  def license_image(license_code)
    gcode = Hydrus::GenericObject.license_group_code(license_code)
    lcode = license_code.downcase.gsub('-', '_')
    gcode == 'creativeCommons' ? image_tag("licenses/#{lcode}.png") : ''
  end

  def license_link(license_code)
    hgo   = Hydrus::GenericObject
    txt   = hgo.license_human(license_code)
    gcode = hgo.license_group_code(license_code)
    url   = hgo.license_group_urls[gcode]
    gcode ? link_to(txt, url) : txt
  end

  def button_color(status)
    status.downcase == 'published' ? 'success' : 'warning'
  end

  def seen_beta_dialog?
    if session[:seen_beta_dialog]
      true
    else
      session[:seen_beta_dialog]=true
      false
    end
  end

  def render_head_content
    content_for(:head)
  end

  def render_contextual_layout
    controller.controller_name == 'catalog' || controller.controller_name == 'sessions' ? (render 'shared/home_contents') : (render 'shared/main_contents')
  end

  def hydrus_signin_link
    if Dor::Config.hydrus.show_standard_login
      link_to('Sign in', new_user_session_path, class: 'signin_link')
    else
      link_to('Sign in via WebAuth', webauth_login_path)
    end
  end

  def new_user_session_path options = {}
    super({referrer: request.fullpath}.merge options)
  end

  def webauth_login_path options = {}
    super({referrer: request.fullpath}.merge options)
  end

  def terms_of_deposit_path(pid)
    url_for(controller: 'hydrus_items',action: 'terms_of_deposit',pid: pid)
  end

  def terms_of_deposit_agree_path(pid)
    url_for(controller: 'hydrus_items',action: 'agree_to_terms_of_deposit',pid: pid)
  end

  def hydrus_strip(value)
    value.nil? ? '' : value.strip
  end

  # Returns true if the Edit tab should be shown for the Collection or Item.
  #   - User can edit the object.
  #   - Object is not published.
  def show_item_edit(item)
    return false unless can?(:edit, item)
    ! item.is_published
  end

  def edit_item_text(item)
    'Edit Draft'
  end

  # text to show on item view tab
  def view_item_text(item)
    item.is_published ? 'Published Version' : 'View Draft'
  end

  def hydrus_object_setting_value(obj, opts = {})
    return obj unless hydrus_is_empty?(obj)
    if opts[:na]
      return content_tag(:span, 'not available yet', class: 'muted')
    else
      return content_tag(:span, 'to be entered', class: 'unspecified')
    end
  end

  # Takes a string. Escapes any HTML characters, converts
  # newlines to <br> tags, and then declars the string to be
  # safe for direct display as HTML.
  def show_line_breaks(txt)
    html_escape(txt).gsub(/\r\n?|\n/, '<br/>').html_safe
  end

  def title_text(obj)
    obj.title.blank? ? 'Untitled' : obj.title
  end

  def delete_confirm_msg(obj)
    msg = "Are you sure you want to discard this #{obj.object_type}?"
    msg += ' This action is permanent and cannot be undone.'
    msg
  end

  # a helper to create links to items that may or may not have titles yet
  def title_link(obj)
    link_to(title_text(obj), polymorphic_path(obj),disable_after_click: 'true')
  end

  # this checks to see if the object passed in is "empty", which could be nil,
  # a blank string, an array of strings with all elements that are blank, an
  # arbitrary object whose attributes are all blank, or an array of arbitrary
  # objects whose attributes are all blank
  def hydrus_is_empty?(obj)
    if obj.nil? # nil case
      is_blank=true
    elsif obj.class == Array # arrays
      is_blank=obj.all? { |element| hydrus_is_empty?(element) }
    elsif obj.class == String # strings
      is_blank=obj.blank?
    else # case of abitrary object
      is_blank=hydrus_is_object_empty?(obj)
    end
    is_blank
  end

  # this checks to see if the object passed in has attributes that are all blank
  def hydrus_is_object_empty?(obj)
    !obj.attribute_names.collect { |attribute| obj.send(attribute).blank? }.include?(false)
  end

  def render_contextual_navigation(model)
    render partial: "#{view_path_from_model(model)}/navigation"
  end

  def view_path_from_model(model)
    model.class.to_s.pluralize.parameterize('_')
  end

  def select_status_checkbox_icon(field)
    content_tag(:i, nil, class: field ? 'icon-check' : 'icon-minus')
  end

  # Takes a value.
  # Returns it as a string, in double-quotes.
  # Nil will stringify to ''.
  def in_quotes(val)
    %Q("#{val}")
  end

  def sdr_mail_to
    mt = mail_to('sdr-contact@lists.stanford.edu', 'sdr-contact@lists.stanford.edu')
    mt.html_safe
  end

  def google_analytics
    (
      <<-HTML
        <script>
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

          ga('create', '#{GOOGLE_ANALYTICS_CODE}', 'auto');
          ga('send', 'pageview');

        </script>
      HTML
    ).html_safe
  end

end
