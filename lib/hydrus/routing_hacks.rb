# NOTE: Chris Beer is responsible for this code -- his masterpiece!!

module Hydrus::RoutingHacks

  def sdoc_up(prefix, suffix, *args)
    doc = args.first
    url_params = {
      :controller => 'catalog',
      :action     => 'show', 
      :only_path  => suffix == '_url',
    }
    case doc
    when Hash
      url_for(url_params.merge doc)
    else
      send(prefix + doc.route_key + suffix, *args)
    end
  end

  def solr_document_path(*args)
    sdoc_up('', '_path', *args)
  end

  def solr_document_url(*args)
    sdoc_up('', '_url', *args)
  end

  def edit_solr_document_path(*args)
    sdoc_up('edit_', '_path', *args)
  end

  def edit_solr_document_url(*args)
    sdoc_up('edit_', '_url', *args)
  end

  def catalog_path(*args)
    doc = args.first
    case doc
    when SolrDocument
      sdoc_up('', '_path', *args)
    when Hash
      super
    else
      polymorphic_path(*args)
    end
  end

  def catalog_url(*args)
    doc = args.first
    case doc
    when SolrDocument
      sdoc_up('', '_url', *args)
    when Hash
      super
    else
      polymorphic_url(*args)
    end
  end

  def edit_catalog_path(*args)
    doc = args.first
    case doc
    when Hash
      super
    else
      edit_polymorphic_path(*args)
    end
  end

  def edit_catalog_url(*args)
    doc = args.first
    case doc
    when Hash
      super
    else
      edit_polymorphic_url(*args)
    end
  end

end
