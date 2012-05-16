# NOTE: Crazy temporary hacks here. Speak with Chris Beer and Monty Hindman.

module Hydrus::RoutingHacks

  def catalog_path           (*args);  cat_up('',       '_path', *args)  end
  def catalog_url            (*args);  cat_up('',       '_url',  *args)  end
  def edit_catalog_path      (*args);  cat_up('edit_',  '_path', *args)  end
  def edit_catalog_url       (*args);  cat_up('edit_',  '_url',  *args)  end
  def solr_document_path     (*args);  sdoc_up('',      '_path', *args)  end
  def solr_document_url      (*args);  sdoc_up('',      '_url',  *args)  end
  def edit_solr_document_path(*args);  sdoc_up('edit_', '_path', *args)  end
  def edit_solr_document_url (*args);  sdoc_up('edit_', '_url',  *args)  end

  def cat_up(prefix, suffix, *args)
    # The catalog _url or _path.
    doc = args.first
    case doc
    when SolrDocument
      sdoc_up(prefix, '_path', *args)
    when Hash
      url_params = {
        :controller => 'catalog',
        :action     => 'show', 
        :only_path  => suffix == '_path',
      }
      url_for(url_params.merge doc)
    else
      send(prefix + 'polymorphic' + suffix, *args)
    end
  end

  def sdoc_up(prefix, suffix, *args)
    # The _url or _path for a SolrDocument.
    doc = args.first
    url_params = {
      :controller => 'catalog',
      :action     => 'show', 
      :only_path  => suffix == '_path',
    }
    case doc
    when Hash
      url_for(url_params.merge doc)
    else
      send(prefix + doc.route_key + suffix, *args)
    end
  end

end
