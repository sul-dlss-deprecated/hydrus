class Hydrus::Collection < Hydrus::GenericObject

  def hydrus_items
    query = %Q(is_member_of_collection_s:"info:fedora/#{pid}")
    resp  = Blacklight.solr.find('q'.to_sym => query)
    items = resp.docs.map { |d| Hydrus::Item.find(d.id) }
    return items
  end

  # These getters and setters are needed because the ActiveFedora delegate()
  # does not work when we need to delegate through to the APO.

  def embargo *args
    apo.embargo *args
  end

  def embargo= *args
    apo.embargo= *args
  end

  def release *args
    apo.release *args
  end

  def release= *args
    apo.release= *args
  end

  def license *args
    apo.license *args
  end

  def license= *args
    apo.license= *args
  end

  def manager *args
    apo.manager *args
  end

  def manager= *args
    apo.manager= *args
  end

end
