class Hydrus::Collection < Hydrus::GenericObject

  # Any time we save a Collection, save its corresponding APO.

  before_save :save_apo

  def save_apo
    apo.save
  end

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

  def embargo_option *args
    apo.embargo_option *args
  end

  def embargo_option= *args
    apo.embargo_option= *args
  end

  def visibility *args
    apo.visibility *args
  end

  def visibility= *args
    apo.visibility= *args
  end

  def visibility_option *args
    apo.visibility_option *args
  end

  def visibility_option= *args
    apo.visibility_option= *args
  end

  def license *args
    apo.license *args
  end

  def license= *args
    apo.license= *args
  end

  def license_option *args
    apo.license_option *args
  end

  def license_option= *args
    apo.license_option= *args
  end

  def collection_manager *args
    apo.collection_manager *args
  end

  def collection_manager= *args
    apo.collection_manager= *args
  end

end
