module HydrusFormHelper
  def hydrus_form_label(opts={}, &block)
    html = ''
    html << "<div class='col-sm-#{opts.has_key?(:columns) ? opts[:columns] : "1"} form-label #{opts[:class] if opts.has_key?(:class)}'>"
    html << capture(&block)
    html << '</div>'
    html.html_safe
  end

  def hydrus_form_value(opts={}, &block)
    html = ''
    html << "<div class='col-sm-#{opts.has_key?(:columns) ? opts[:columns] : "8"} #{opts[:class] if opts.has_key?(:class)}'>"
    html << capture(&block)
    html << '</div>'
    html.html_safe
  end

  def syntax_highlighted_datastream(obj, dsid)
    xml = Nokogiri.XML(obj.datastreams[dsid].content, &:noblanks)
    CodeRay::Duo[:xml, :div].highlight(xml).html_safe
  end
end
