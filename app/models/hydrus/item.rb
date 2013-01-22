class Hydrus::Item < Hydrus::GenericObject

  include Hydrus::Responsible
  include Hydrus::EmbargoMetadataDsExtension
  extend  Hydrus::Delegatable
  extend  Hydrus::Cant

  REQUIRED_FIELDS = [:title, :abstract, :contact, :keywords, :version_description]

  after_validation :strip_whitespace

  validates :title,               :not_empty => true, :if => :should_validate
  validates :abstract,            :not_empty => true, :if => :should_validate
  validates :contact,             :not_empty => true, :if => :should_validate
  validates :keywords,            :not_empty => true, :if => :should_validate
  validates :version_description, :not_empty => true, :if => lambda {
    should_validate() && ! is_initial_version()
  }

  validate  :enforce_collection_is_open,     :on => :create
  validates :actors, :at_least_one => true,  :if => :should_validate
  validates :files,  :at_least_one => true,  :if => :should_validate
  validate  :must_accept_terms_of_deposit,   :if => :should_validate
  validate  :must_review_release_settings,   :if => :should_validate
  validate  :embargo_date_is_correct_format, :if => :should_validate
  validate  :embargo_date_in_range,          :if => :should_validate
  validates :license, :presence => true,     :if => :should_validate

  setup_delegations(
    # [:METHOD_NAME,               :uniq, :at... ]
    "descMetadata" => [
      [:preferred_citation,        true   ],
      [:related_citation,          false  ],
      [:person,                    false, :name, :namePart],
      [:person_role,               false, :name, :role, :roleTerm],
    ],
    "roleMetadata" => [
      [:item_depositor_id,         true,  :item_depositor, :person, :identifier],
      [:item_depositor_name,       true,  :item_depositor, :person, :name],
    ],
    "hydrusProperties" => [
      [:reviewed_release_settings, true   ],
      [:accepted_terms_of_deposit, true   ],
      [:version_started_time,      true   ],
    ]
  )

  has_metadata(
    :name => "roleMetadata",
    :type => Hydrus::RoleMetadataDS,
    :label => 'Role Metadata',
    :control_group => 'M')


  # Note: currently all items of of type :dataset. In the future,
  # the calling code can pass in the needed value.
  def self.create(collection_pid, user, itype = :dataset)
    # Make sure user can create items in the parent collection.
    coll = Hydrus::Collection.find(collection_pid)
    cannot_do(:create) unless coll.is_open()
    cannot_do(:create) unless Hydrus::Authorizable.can_create_items_in(user, coll)
    # Create the object, with the correct model.
    dor_item = Hydrus::GenericObject.register_dor_object(user, 'item', coll.apo_pid)
    item     = dor_item.adapt_to(Hydrus::Item)
    item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
    item.assert_content_model
    # Add the Item to the Collection.
    item.add_to_collection(coll.pid)
    # Create default rightsMetadata from the collection
    #item.rightsMetadata.content = coll.rightsMetadata.ng_xml.to_s
    # Set the item_type, and add some Hydrus-specific info to identityMetadata.
    item.item_type = itype.to_s
    item.augment_identity_metadata(itype)
    # Add roleMetadata with current user as hydrus-item-depositor.
    item.roleMetadata.add_person_with_role(user, 'hydrus-item-depositor')
    # Set default embargo and visibility.
    if coll.embargo_option == 'fixed'
      item.embargo_date = HyTime.date_display(item.end_of_embargo_range)
    end
    vov = coll.visibility_option_value
    item.visibility = vov == 'stanford' ? vov : 'world'
    # Set default license
    clo = coll.license_option
    item.license = clo == 'none'  ? clo :
                   clo == 'fixed' ? item.collection.license : nil
    # Set object status.
    item.object_status = 'draft'
    # Set version info.
    # The call to content_will_change! forces the instantiation of the versionMetadata XML.
    item.version_started_time = HyTime.now_datetime
    item.versionMetadata.content_will_change!
    # Add event.
    item.events.add_event('hydrus', user, "Item created")
    # Check to see if this user needs to agree again for this new item, if not,
    # indicate agreement has already occured automatically
    if item.requires_terms_acceptance(user.to_s,coll) == false
      item.accepted_terms_of_deposit = "true"
      msg = 'Terms of deposit accepted due to previous item acceptance in collection'
      item.events.add_event('hydrus', user, msg)
    else
      item.accepted_terms_of_deposit="false"
    end
    # Save and return.
    item.save(:no_edit_logging => true, :no_beautify => true)
    return item
  end

  # Publish the Item directly, bypassing human approval.
  def publish_directly
    cannot_do(:publish_directly) unless is_publishable()
    complete_workflow_step('submit')
    do_publish()
  end

  # A method to implement the steps steps associated with publishing an Item.
  # Called by publish_directly() and approve(), not by the controller.
  def do_publish
    t = title()
    self.publish_time = HyTime.now_datetime
    identityMetadata.objectLabel = t
    self.label = t
    self.object_status = 'published'
    complete_workflow_step('approve')
    close_version() unless is_initial_version()
    events.add_event('hydrus', @current_user, "Item published: #{version_tag()}")
    start_common_assembly()
  end

  # Submit the Item for approval by a reviewer.
  # This method handles the initial submission, not resubmissions.
  def submit_for_approval
    cannot_do(:submit_for_approval) unless is_submittable_for_approval()
    self.submit_for_approval_time   = HyTime.now_datetime
    self.object_status = 'awaiting_approval'
    complete_workflow_step('submit')
    events.add_event('hydrus', @current_user, "Item submitted for approval")
  end

  # Approve the Item.
  def approve
    cannot_do(:approve) unless is_approvable()
    hydrusProperties.remove_nodes(:disapproval_reason)
    events.add_event('hydrus', @current_user, "Item approved")
    do_publish()
  end

  # Disapprove the Item -- return it for further editing.
  # Expects to receive a hash with a 'reason' key.
  def disapprove(reason)
    cannot_do(:disapprove) unless is_disapprovable()
    self.object_status      = 'returned'
    self.disapproval_reason = reason
    events.add_event('hydrus', @current_user, "Item returned")
    send_object_returned_email_notification()
  end

  # Resubmits an object after it was disapproved/returned.
  def resubmit
    cannot_do(:resubmit) unless is_resubmittable()
    self.submit_for_approval_time   = HyTime.now_datetime
    self.object_status = 'awaiting_approval'
    hydrusProperties.remove_nodes(:disapproval_reason)
    events.add_event('hydrus', @current_user, "Item resubmitted for approval")
  end

  # Opens a new version of the Item.
  # Notes:
  #   - After an Item is published, in order to make further edits, the
  #     user must open a new version.
  #   - The :no_super option is used solely to prevent the super() call
  #     during testing.
  def open_new_version(opts = {})
    cannot_do(:open_new_version) unless is_accessioned()
    # Call the dor-services method, with a couple of Hydrus-specific options.
    super(:assume_accessioned => should_treat_as_accessioned(), :create_workflows_ds => false)
    # Set some version metadata that the Hydrus app uses.
    versionMetadata.update_current_version(:description => '', :significance => :major)
    self.version_started_time = HyTime.now_datetime
    # Put the object back in the draft state.
    self.object_status = 'draft'
    uncomplete_workflow_steps()
    # Log the event.
    events.add_event('hydrus', @current_user, "New version opened")
  end

  # Closes the current version of the Item.
  # This occurs when an Item is published, unless it was the initial version.
  # See do_publish(), where all of the Hydrus-specific work is done; here
  # we simply invoke the dor-services method.
  def close_version
    cannot_do(:close_version) if is_initial_version()
    super(:version_num => version_id, :start_accession => false)
  end

  # indicates if this item has an accepted terms of deposit, or if the supplied
  # user (logged in user) has accepted a terms of deposit for another item in
  # this collection within the last year you can pass in a specific collection
  # to check, if not specified, defaults to this item's collection (useful when
  # creating new items)
  def requires_terms_acceptance(user,coll=self.collection)
    if to_bool(accepted_terms_of_deposit)
      # if this item has previously been accepted, no further checks are needed
      return false
    else
      # if this item has not been accepted, let's look at the collection.
      # Get the users who have accepted the terms of deposit for any other items in this collection.
      # If there are users, find out if the supplied user is one of them.
      # And if so, have they agreed within the last year?
      users = coll.users_accepted_terms_of_deposit
      if users && users.keys.include?(user)
        dt = coll.users_accepted_terms_of_deposit[user].to_datetime
        return (HyTime.now - 1.year) > dt
      else
        return true
      end
    end
  end

  # Returns true if the object can be submitted for approval:
  # a valid draft object that actually requires human approval.
  # Note: returned is not a valid object_status here, because this
  # test concerns itself with the initial submission for approval.
  def is_submittable_for_approval
    return false unless object_status == 'draft'
    return false unless to_bool(requires_human_approval)
    return validate!
  end

  # Returns true if the object is waiting for approval by a reviewer.
  def is_awaiting_approval
    return object_status == 'awaiting_approval'
  end

  # Returns true if the object status is currently returned-by-reviewer.
  def is_returned
    return object_status == 'returned'
  end

  # Returns true if the object can be approved by a reviewer.
  def is_approvable
    return false unless is_awaiting_approval
    return validate!
  end

  # Returns true if the object can be returned by a reviewer.
  def is_disapprovable
    return is_awaiting_approval
  end

  # Returns true if the object can be resubmitted for approval.
  def is_resubmittable
    return false unless is_returned
    return validate!
  end

  # Returns true if the item is publishable: must be valid and must
  # have the correct object_status.
  def is_publishable
    return false unless validate!
    return is_awaiting_approval if to_bool(requires_human_approval)
    return is_draft
  end

  # Returns true if the object is ready for common assembly.
  # It's not strictly necessary to involve validate!, but it provides extra insurance.
  def is_assemblable
    return false unless is_published
    return validate!
  end

  # Returns true only if the Item is unpublished.
  def is_destroyable
    return not(is_published)
  end

  # Returns the Item's Collection.
  def collection
    cs = super       # Get all collections.
    return cs.first  # In Hydrus, we assume there is just one (for now).
  end

  def requires_human_approval
    # Delegate this question to the collection.
    collection.requires_human_approval
  end

  # method used to build sidebar
  def files_uploaded?
    validate! ? true : !errors.keys.include?(:files)
  end

  # method used to build sidebar
  def terms_of_deposit_accepted?
    validate! ? true : !errors.keys.include?(:terms_of_deposit)
  end

  # method used to build sidebar
  def reviewed_release_settings?
    validate! ? true : !errors.keys.include?(:release_settings)
  end

  # A validation used before creating a new Item.
  # Returns true if the collection is open; otherwise,
  # returns false and adds a validation error.
  def enforce_collection_is_open
    c = collection
    return true if c && c.is_open
    errors.add(:collection, "must be open to have new items added")
    return false
  end

  # the user must accept the terms of deposit to publish
  def must_accept_terms_of_deposit
     if to_bool(accepted_terms_of_deposit) != true
       errors.add(:terms_of_deposit, "must be accepted")
     end
  end

  # the user must have reviewed the release and visibility settings
  def must_review_release_settings
    if to_bool(reviewed_release_settings) != true
      errors.add(:release_settings, "must be reviewed")
    end
  end

  # Accepts terms of deposit for the given user.
  # At the item level we store true/false.
  # At the colleciton level we store user name and datetime.
  def accept_terms_of_deposit(user)
    cannot_do(:accept_terms_of_deposit) unless Hydrus::Authorizable.can_edit_item(user, self)
    self.accepted_terms_of_deposit = "true"
    collection.accept_terms_of_deposit(user, HyTime.now_datetime, self)
    events.add_event('hydrus', user, 'Terms of deposit accepted')
  end

  # Return's true if the Item belongs to a collection that allows
  # Items to set their own embargoes.
  def embargoes_can_vary
    return collection.embargo_option == 'varies'
  end

  # Return's true if the Item belongs to a collection that allows
  # Items to set their own licenses.
  def visibilities_can_vary
    return collection.visibility_option == 'varies'
  end

  # Return's true if the Item belongs to a collection that allows
  # Items to set their own licenses.
  def licenses_can_vary
    return collection.license_option == 'varies'
  end

  # Takes a hash with the following keys and possible values:
  #
  #     'embargoed'  => 'yes'
  #                     'no'
  #                     nil            # Form did not offer embargo choice.
  #
  #     'date'       => 'YYYY-MM-DD'
  #                     nil            # Form did not offer embargo choice.
  #
  #     'visibility' => 'world'
  #                     'stanford'
  #                     nil            # Form did not offer visibility choice.
  #
  # Given that hash, we call the embargo_date and visibility
  # setters. The UI invovkes this combined setter (not the individual
  # setters), because we want to ensure that the individual setters
  # are called in the desired order. This is necessary because the
  # visibility setter needs to know the Item's embargo status.
  def embarg_visib=(opts)
    e  = opts['embargoed']
    d  = opts['date']
    v  = opts['visibility']
    dt = to_bool(e) ? d : ''
    self.embargo_date = dt unless e.nil?
    self.visibility   = v  unless v.nil?
  end

  # Returns true if the Item is embargoed.
  def is_embargoed
    return not(embargo_date.blank?)
  end

  # Returns the embargo date from the embargoMetadata, not the rightsMetadata.
  # We don't use the latter because it is a convenience copy used by the PURL app.
  def embargo_date
    return embargoMetadata ? embargoMetadata.release_date : nil
  end

  # Sets the embargo date in both embargoMetadata and rightsMetadata.
  # The new value is assumed to be expressed in the local time zone.
  # If the new date is blank or nil, the embargoMetadata datastream is deleted.
  # Do not call this directly from the UI. Instead, use embarg_visib=().
  def embargo_date= val
    ed = HyTime.datetime(val, :from_localzone => true)
    if ed.blank?
      rightsMetadata.remove_embargo_date
      embargoMetadata.delete
    else
      self.rmd_embargo_release_date = ed
      embargoMetadata.release_date  = ed
      embargoMetadata.status        = 'embargoed'
    end
  end

  def embargo_date_in_range
    return unless is_embargoed
    b  = beginning_of_embargo_range.to_datetime
    e  = end_of_embargo_range.to_datetime
    dt = embargo_date.to_datetime
    unless (b <= dt and dt <= e)
      b = HyTime.date_display(b)
      e = HyTime.date_display(e)
      errors.add(:embargo_date, "must be in the range #{b} - #{e}")
    end
  end

  # Returns the publish_time or now, as a datetime string.
  def beginning_of_embargo_range
    return publish_time || HyTime.now_datetime
  end

  # Parses embargo_terms (eg, "2 years") into its number and time-unit parts.
  # Uses those parts to add a time increment (eg 2.years) to the beginning
  # of the embargo range. Returns that result as a datetime string.
  def end_of_embargo_range
    n, time_unit = collection.embargo_terms.split
    dt = beginning_of_embargo_range.to_datetime + n.to_i.send(time_unit)
    return HyTime.datetime(dt)
  end

  def embargo_date_is_correct_format
    return unless is_embargoed
    begin
     embargo_date.to_datetime
    rescue ArgumentError
     msg = "must be a valid date (#{HyTime::DATE_PICKER_FORMAT})"
     errors.add(:embargo_date, msg)
    end
  end

  # Returns visibility as an array -- typically either ['world'] or ['stanford'].
  # Embargo status determines which datastream is used to obtain the information.
  def visibility
    ds = is_embargoed ? embargoMetadata : rightsMetadata
    return ["world"] if ds.has_world_read_node
    return ds.group_read_nodes.map { |n| n.text }
  end

  # Takes a visibility -- typically 'world' or 'stanford'.
  # Modifies the embargoMetadata and rightsMetadata based on that visibility
  # values, along with the embargo status.
  # Do not call this directly from the UI. Instead, use embarg_visib=().
  def visibility= val
    if is_embargoed
      # If embargoed, we set access info in embargoMetadata.
      embargoMetadata.initialize_release_access_node(:generic)
      embargoMetadata.update_access_blocks(val)
      # And we clear our read access in rightsMetadata.
      rightsMetadata.remove_world_read_access
      rightsMetadata.remove_group_read_nodes
    else
      # Otherwise, just set access info in rightsMetadata.
      # The embargoMetadata should not exist at this point.
      rightsMetadata.update_access_blocks(val)
    end
  end

  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight')
  end

  def strip_whitespace
    strip_whitespace_from_fields [:preferred_citation,:title,:abstract,:contact]
  end

  def actors
    @actors ||= descMetadata.find_by_terms(:name).collect do |actor_node|
      name_node=actor_node.at_css('namePart')
      role_node=actor_node.at_css('role roleTerm')
      name = (name_node.respond_to?(:content) and !name_node.content.blank?)     ? name_node.content : ''
      role = (role_node.respond_to?(:content) and !role_node.content.blank?) ? role_node.content : ''
      Hydrus::Actor.new(:name=>name,:role=>role)
    end
  end

  def add_to_collection(pid)
    uri = "info:fedora/#{pid}"
    add_relationship_by_name('set', uri)
    add_relationship_by_name('collection', uri)
  end

  def remove_from_collection(pid)
    uri = "info:fedora/#{pid}"
    remove_relationship_by_name('set', uri)
    remove_relationship_by_name('collection', uri)
  end

  def keywords(*args)
    descMetadata.subject.topic(*args)
  end

  # Takes a comma-delimited string.
  # Parses the string and rewrites the Item's descMD subject nodes
  # (but only if the parsed keywords differ from the current subject nodes).
  def keywords=(val)
    kws = Hydrus::ModelHelper.parse_delimited(val)
    return if keywords == kws
    descMetadata.remove_nodes(:subject)
    kws.each { |kw| descMetadata.insert_topic(kw)  }
  end

  def self.person_roles
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

  def self.discovery_roles
    return {
      "everyone"      => "world",
      "Stanford only" => "stanford",
    }
  end

  # See GenericObject#changed_fields for discussion.
  def tracked_fields
    return {
      :title      => [:title],
      :abstract   => [:abstract],
      :files      => [:files_were_changed],
      :embargo    => [:embargo_date],
      :visibility => [:visibility],
      :license    => [:license],
    }
  end

  # Returns the Item's current version number, 1..N.
  def version_id
    return current_version
  end

  # Returns the Item's current version tag, eg v2.2.0.
  def version_tag
    return 'v' + versionMetadata.current_tag
  end

  # Returns the description of the current version.
  def version_description
    return versionMetadata.description_for_version(current_version)
  end

  # Returns true if the current version is the initial version.
  def is_initial_version
    return self.current_version == '1'
  end

  # Takes a string.
  # Sets the description of the current version.
  def version_description=(val)
    versionMetadata.update_current_version(:description => val)
  end

  # Takes a string or symbol: major, minor, admin.
  # Sets the significance of the current version.
  def version_significance=(val)
    versionMetadata.update_current_version(:significance => val.to_sym)
  end

  # Returns the significance (major, minor, or admin) of the current version.
  # This method probably belongs in dor-services gem.
  def version_significance
    tags = versionMetadata.find_by_terms(:version, :tag).
           map{ |t| Dor::VersionTag.parse(t.value) }.sort
    return :major if tags.size < 2
    curr = tags[-1]
    prev = tags[-2]
    return prev.major != curr.major ? :major :
           prev.minor != curr.minor ? :minor : :admin
  end

end

class Hydrus::ItemWithoutCollectionError < StandardError
end
