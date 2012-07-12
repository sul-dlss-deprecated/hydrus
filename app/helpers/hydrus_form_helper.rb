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

  # WARNING - the keys of this hash (which appear in the radio buttons in the colelction edit page) 
  #   are used in the collection model to trigger specific getting and setting behavior of embargo lengths
  #  if you change these keys here, you need to update the collection model as well
  def embargo_types
    return {
      'none'   => 'no delay -- release all items as soon as they are deposited',
      'varies' => 'varies -- select a release date per item, from "now" to a maximum of',
      'fixed'  => 'fixed -- delay release of all items for',
    }
  end

  def visibility_types
    return {
      'fixed' => 'everyone -- all items in this collection will be public',
      'varies'   => 'varies -- default is public, but you can choose to restrict some items to Stanford community',
      # FIXME:  this is wrong per https://consul.stanford.edu/display/HYDRUS/Create+a+Collection+-+notes+on+APO-related+fields
      #   as both the first and this last value have option attr set to fixed ... but changes are expected.  2012-07-09
      'stanford' => 'Stanford community -- all items will be visible only to Stanford-authenticated users',
    }
  end

  def embargo_terms
    return [
      '6 months after deposit',
      '1 year after deposit',
      '2 years after deposit',
      '3 years after deposit',
    ]
  end

end
