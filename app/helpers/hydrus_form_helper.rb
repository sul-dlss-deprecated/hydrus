module HydrusFormHelper
  
  def hydrus_form_label(opts={})
    html = ""
    html << "<div class='span#{opts.has_key?(:columns) ? opts[:columns] : "2"} form-label #{opts[:class] if opts.has_key?(:class)}'>"
      html << yield
    html << "</div>"
    html.html_safe
  end
  
  def hydrus_form_value(opts={})
    html = ""
    html << "<div class='span#{opts.has_key?(:columns) ? opts[:columns] : "7"} #{opts[:class] if opts.has_key?(:class)}'>"
      html << yield
    html << "</div>"
    html.html_safe
  end
  
  def hydrus_form_header(opts={})
    html = ""
    html << "<div class='row section-header'>"
      html << "<div class='span8'>"
        html << "<h3>#{yield}</h3>"
      html << "</div>"
      if opts.has_key?(:required) and opts[:required]
        html << "<div class='span1'>"
          html << "<div class='required'>required</div>"
        html << "</div>"
      end
    html << "</div>"
    html.html_safe
  end
  
  def people_roles
    ["Author", "Creator", "Collector", "Contributing Author", "Distributor", "Principal Investigator", "Publisher", "Sponsor"]
  end
  
end