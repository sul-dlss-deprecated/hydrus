class Hydrus::Collection < Hydrus::GenericObject

  # Any time we save a Collection, save its corresponding APO.

  after_validation :strip_whitespace
  before_save :save_apo
  
  # this lets us check if both the apo and the collection are valid at once (used in the controller)
  def object_valid?
    valid? # first run the validations on BOTH models specifically to collect all errors
    apo.valid?
    valid? && apo.valid? # then return true only if both are actually valid
  end
  
  def object_error_messages
    # grab all error messages from both collection and the apo to show to the user
    errors.messages.merge(apo.errors.messages)
  end
    
  def publish=(value)
    # set the APO to published if the collection is published, since they are tied together, so that we only run validations when both are published
    apo.publish=true if to_bool(value)
    super
  end
  
  def strip_whitespace
     strip_whitespace_from_fields [:title,:abstract,:contact]
  end

  def save_apo
    remove_values_for_associated_attribute_with_value_none
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
#    args [{"0"=>"brown", "1"=>"xxxx", "2"=>"ggreen", "3"=>"abcde"}]
    
    # for each person in the lsit
    #   get their role (using controller's person_role information)  NOTE:  may not work if you want to change a persons role
    #   now ensure that roleMetadata has the person in the role in the xml
    #  AND ensure that the roleMetadata does NOT have any persons that are NOT in our list
     #   
 
#    apo.person_id= *args
#    values = args.first
#    values.each { |k, v|  
#      apo.person_id= v
#    }
  end
  
  def get_person_role *args
    apo.roleMetadata.get_person_role *args
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def person_role= *args
#    args [{"0"=>"collection-manager", "1"=>"collection-manager", "2"=>"collection-depositor", "3"=>"coll_cntlr_update_method_hardcoded"}]
    
#puts "DEBUG: person_role args are #{args.inspect}"
#    apo.roleMetadata.add_person_of_role *args
  end

end
