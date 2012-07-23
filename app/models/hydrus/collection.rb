class Hydrus::Collection < Hydrus::GenericObject

  # Any time we save a Collection, save its corresponding APO.

  before_validation :remove_values_for_associated_attribute_with_value_none
  after_validation :strip_whitespace
  before_save :save_apo
  
  def self.create(user)
    apo = Hydrus::AdminPolicyObject.create(user)
    dor_obj = Hydrus::GenericObject.register_dor_object(user, 'collection', apo.pid)
    collection = dor_obj.adapt_to(Hydrus::Collection)
    collection.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Collection'
    collection.assert_content_model
    collection.save
    return collection
  end

  # this lets us check if both the apo and the collection are valid at once (used in the controller)
  def object_valid?
    valid? # first run the validations on BOTH collection and apo models specifically to collect all errors
    apo.valid?
    valid? && apo.valid? # then return true only if both are actually valid
  end
  
  def object_error_messages
    # grab all error messages from both collection and the apo to show to the user
    errors.messages.merge(apo.errors.messages)
  end
    
  def publish=(value)
    # set the APO deposit status to open if the collection is published, since they are tied together
    apo.deposit_status = (to_bool(value) ? "open" : "closed")
  end
  
  def publish
    apo.deposit_status == "open" ? true : false
  end
  
  def strip_whitespace
     strip_whitespace_from_fields [:title,:abstract,:contact]
  end

  def save_apo
    apo.save
  end

  def remove_values_for_associated_attribute_with_value_none
    self.embargo = nil if self.embargo_option == "none"
    self.license = nil if self.license_option == "none"
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
  
  # These getter and setter methods allow us to set a single value for the embargo 
  #  period and license from two separate HTML select controls, based on the value of a radio button
  def embargo_varies
    embargo_option == "varies" ? embargo : ""
  end

  def embargo_fixed
    embargo_option == "fixed" ? embargo : ""
  end

  def embargo_varies= *args
    apo.embargo= *args if embargo_option == "varies" # only set the embargo period for this setter if the corresponding radio button is selected
  end

  def embargo_fixed= *args
    apo.embargo= *args if embargo_option == "fixed"  # only set the embargo period for this setter if the corresponding radio button is selected
  end

  def license_varies
    license_option == "varies" ? license : ""
  end

  def license_fixed
    license_option == "fixed" ? license : ""
  end

  def license_varies= *args
    apo.license= *args if license_option == "varies" # only set the license for this setter if the corresponding radio button is selected
  end

  def license_fixed= *args
    apo.license= *args if license_option == "fixed"  # only set the license for this setter if the corresponding radio button is selected
  end
  #############
  
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

  def vov_lookup
    return {
      'everyone'       => 'fixed_world',
      'varies'         => 'varies_world',
      'stanford'       => 'fixed_stanford',
      'fixed_world'    => 'everyone',
      'varies_world'   => 'varies',
      'fixed_stanford' => 'stanford',
    }
  end

  def visibility_option_value *args
    opt = apo.visibility_option # fixed or varies
    vis = apo.visibility        # world or stanford
    return vov_lookup["#{opt}_#{vis}"]
  end

  def visibility_option_value= *args
    opt, vis              = vov_lookup[args.first].split('_')
    apo.visibility_option = opt # fixed or varies
    apo.visibility        = vis # world or stanford
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
   
  def collection_owner *args
    apo.collection_owner *args
  end

  def person_id *args
    apo.person_id *args
  end
  
  def person_id= *args
    # this is a no-op because we use the person_roles=  method below to assign ids 
  end
  
  def get_person_role *args
    apo.roleMetadata.get_person_role *args
  end
  
  def add_empty_person_to_role *args
    apo.roleMetadata.add_empty_person_to_role *args
  end
  
  def person_role= *args
    # this is a no-op because we use the person_roles=  method below to assign roles 
  end
  
  # Takes a hash of SUNETIDs and roles.
  # Rewrites roleMetadata to reflect the contents of the hash.
  # Example input
  #   {
  #     "brown"   => "collection-manager",
  #     "dblack"  => "collection-manager",
  #     "ggreen"  => "collection-depositor",
  #   }
  def person_roles= *args
    apo.roleMetadata.remove_nodes(:role)
    args.first.each { |id, role|
      apo.roleMetadata.add_person_with_role(id, role)
    }
  end
  
  def remove_actor *args
    apo.roleMetadata.delete_actor *args
  end

end
