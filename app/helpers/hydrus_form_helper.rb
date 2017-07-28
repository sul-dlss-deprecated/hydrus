module HydrusFormHelper
  def hydrus_form_label(opts={}, &block)
    html = ''
    html << "<div class='span#{opts.has_key?(:columns) ? opts[:columns] : "1"} form-label #{opts[:class] if opts.has_key?(:class)}'>"
      html << capture(&block)
    html << '</div>'
    html.html_safe
  end

  def hydrus_form_value(opts={}, &block)
    html = ''
    html << "<div class='span#{opts.has_key?(:columns) ? opts[:columns] : "8"} #{opts[:class] if opts.has_key?(:class)}'>"
      html << capture(&block)
    html << '</div>'
    html.html_safe
  end

  def hydrus_form_header(opts={}, &block)
    html = ''
    html << "<div class='row section-header#{' first-header' if opts.has_key?(:first)}'>"
      html << "<div class='span9'>"
        if opts.has_key?(:required) && opts[:required]
          html << "<span class='required'><span class='label label-important'>required</span></span>"
        end
      html << "<h4>#{capture(&block)}</h4>"
      html << '</div>'
    html << '</div>'
    html.html_safe
  end

  def syntax_highlighted_datastream(obj, dsid)
    xml = Nokogiri.XML(obj.send(dsid).content, &:noblanks)
    CodeRay::Duo[:xml, :div].highlight(xml).html_safe
  end
end
