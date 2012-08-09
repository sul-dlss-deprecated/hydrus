class Hydrus::Collection < Hydrus::GenericObject

  include Hydrus::Responsible

  before_save :save_apo
  before_validation :remove_values_for_associated_attribute_with_value_none
  after_validation :strip_whitespace

  def self.create(user)
    # Create the object, with the correct model.
    apo     = Hydrus::AdminPolicyObject.create(user)
    dor_obj = Hydrus::GenericObject.register_dor_object(user, 'collection', apo.pid)
    coll    = dor_obj.adapt_to(Hydrus::Collection)
    coll.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Collection'
    coll.assert_content_model
    # Add some Hydrus-specific info to identityMetadata.
    coll.augment_identity_metadata(:collection)
    # Add roleMetadata with current user as collection-depositor.
    coll.roleMetadata.add_person_with_role(user, 'collection-depositor')
    # Save and return.
    coll.save
    return coll
  end

  # Returns true only if both the Collection and its APO are valid.
  # Note that we want both validations to run (even if the first fails)
  # so that APO error messages can be merged into those of the Collection.
  def valid?(*args)
    v1 = super
    v2 = apo.valid?
    errors.messages.merge!(apo.errors.messages)
    return v1 && v2
  end

  # Returns true only if the Collection is unpublished and has no Items.
  def is_destroyable
    return not(is_published or has_items)
  end

  # Returns true only if the Collection has items.
  def has_items
    return hydrus_items.size > 0
  end

  # Open or close the Collection.
  # Opening also has the effect of publishing it.
  # Unlike open-close, which the user can toggle, publishing is irreversible.
  def publish(value)
    if to_bool(value)
      apo.deposit_status = 'open'
      # At the moment of publication, we refresh various titles.
      apo.identityMetadata.objectLabel = "APO for #{title}"
      apo.descMetadata.title           = "APO for #{title}"
      identityMetadata.objectLabel     = title
      # Advance the workflow to record that the object has been published.
      s = 'submit'
      complete_workflow_step(s) unless workflow_step_is_done(s)
      approve() unless requires_human_approval
    else
      apo.deposit_status = 'closed'
    end
  end

  def is_open
    return apo.is_open
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

  def deposit_status *args
    apo.deposit_status *args
  end

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
  def add_empty_person_to_role *args
    apo.roleMetadata.add_empty_person_to_role *args
  end

  def collection_owner *args
    apo.collection_owner *args
  end

  def person_id *args
    apo.person_id *args
  end

  def apo_person_roles
    return apo.person_roles
  end

  def apo_person_roles= *args
    apo.person_roles= args.first
  end

  def remove_actor *args
    apo.roleMetadata.delete_actor *args
  end

end
