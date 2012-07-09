module HydrusFormHelper
  
  def hydrus_form_label(opts={}, &block)
    html = ""
    html << "<div class='span#{opts.has_key?(:columns) ? opts[:columns] : "1"} form-label #{opts[:class] if opts.has_key?(:class)}'>"
      html << capture(&block)
    html << "</div>"
    html.html_safe
  end
  
  def hydrus_form_value(opts={}, &block)
    html = ""
    html << "<div class='span#{opts.has_key?(:columns) ? opts[:columns] : "8"} #{opts[:class] if opts.has_key?(:class)}'>"
      html << capture(&block)
    html << "</div>"
    html.html_safe
  end
  
  def hydrus_form_header(opts={}, &block)
    html = ""
    html << "<div class='row section-header#{' first-header' if opts.has_key?(:first)}'>"
      html << "<div class='span9'>"
        html << "<h3>#{capture(&block)}</h3>"
        if opts.has_key?(:required) and opts[:required]
            html << "<span class='required'><span class='label label-important'>required</span></span>"
        end
      html << "</div>"
    html << "</div>"
    html.html_safe
  end
  
  def people_roles
    return [
      "Author",
      "Creator",
      "Collector",
      "Contributing Author",
      "Distributor",
      "Principal Investigator",
      "Publisher",
      "Sponsor",
    ]
  end
 
  # Returns a hash of info needed for licenses in the APO.
  # Keys correspond to the license_option in the OM terminology.
  # Values are displayed in the web form.
  def license_types
    return {
      'none'   => 'no license -- content creator retains exclusive rights',
      'varies' => 'varies -- select a default below; contributor may change it for each item',
      'fixed'  => 'required license -- apply the selected license to all items in the collection',
    }
  end

end
