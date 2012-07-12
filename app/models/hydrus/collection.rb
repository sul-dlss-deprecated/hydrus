class Hydrus::Collection < Hydrus::GenericObject

  # Any time we save a Collection, save its corresponding APO.

  after_validation :strip_whitespace
  before_save :save_apo

  def strip_whitespace
     strip_whitespace_from_fields [:title,:abstract,:contact]
  end

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

  # for APO administrativeMetadata
  
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

  # for APO roleMetadata 
   
  def collection_manager *args
    apo.collection_manager *args
  end

  def collection_manager= *args
    apo.collection_manager= *args
  end
  
  def person_id *args
    apo.person_id *args
  end
  
  def person_id= *args
    apo.person_id= *args
  end
  
  def get_person_role *args
    apo.roleMetadata.get_person_role *args
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def person_role= *args
#puts "DEBUG: person_role args are #{args.inspect}"
#    apo.roleMetadata.add_person_of_role *args
  end

end
