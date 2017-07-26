class Hydrus::Item < Hydrus::GenericObject

  include Hydrus::Responsible
  include Hydrus::EmbargoMetadataDsExtension

  # Override Dor::Governable so that we look for Hydrus::AdminPolicyObjects
  belongs_to :admin_policy_object, property: :is_governed_by, class_name: 'Hydrus::AdminPolicyObject'
  has_and_belongs_to_many :collections, :property => :is_member_of_collection, :class_name => 'Hydrus::Collection'

  REQUIRED_FIELDS = [:title, :abstract, :contact, :keywords, :version_description, :date_created]

  after_validation :strip_whitespace
  attr_accessor :dates
  validates :title,               :not_empty => true, :if => :should_validate
  validates :abstract,            :not_empty => true, :if => :should_validate
  validates :contact,             :not_empty => true, :if => :should_validate
  validates :keywords,            :not_empty => true, :if => :should_validate
  #validates :date_created,        :not_empty => true, :if => :should_validate
  validates :version_description, :not_empty => true, :if => lambda {
    should_validate() && ! is_initial_version()
  }

  validate  :enforce_collection_is_open, :on => :create

  validates :contributors, :at_least_one => true,  :if => :should_validate
  validate  :contributors_not_all_blank,           :if => :should_validate
  validates :files, :at_least_one => true,         :if => :should_validate
  validate  :must_accept_terms_of_deposit,         :if => :should_validate
  validate  :must_review_release_settings,         :if => :should_validate

  validate  :embargo_date_is_well_formed
  validate  :embargo_date_in_range
  validate  :check_version_if_license_changed
  validate  :check_visibility_not_reduced
  validate  :has_specified_a_valid_date,          :if => :should_validate

  belongs_to :collection, property: :is_member_of_collection, class_name: 'Hydrus::Collection'

  # During subsequent versions the user is allowed to change the license,
  # but only if the new version is designated as a major version change.
  def check_version_if_license_changed
    return if is_initial_version
    return if license == prior_license
    return if version_significance == :major
    msg = "must be 'major' if license is changed"
    errors.add(:version, msg)
  end

  # During subsequent versions the user not allowed to reduce visibility.
  def check_visibility_not_reduced
    return if is_initial_version
    v = visibility
    return if v == ['world']
    return if v == [prior_visibility]
    # ap({
    #   :visibility         => visibility,
    #   :prior_visibility   => prior_visibility,
    #   :embargo_date       => embargo_date,
    # })
    msg = "cannot be reduced in subsequent versions"
    errors.add(:visibility, msg)
  end

  setup_delegations(
    # [:METHOD_NAME,               :uniq, :at... ]
    "descMetadata" => [
      [:preferred_citation,        true   ],
      # [:date_created,              true   ],
      [:related_citation,          false  ],
    ],
    "roleMetadata" => [
    #  [:item_depositor_id,         true,  :item_depositor, :person, :identifier],
      [:item_depositor_name,       true,  :item_depositor, :person, :name],
    ],
    "hydrusProperties" => [
      [:reviewed_release_settings, true   ],
      [:accepted_terms_of_deposit, true   ],
      [:version_started_time,      true   ],
      [:prior_license,             true   ],
      [:prior_visibility,          true   ],
    ]
  )

  has_metadata(
    :name => "roleMetadata",
    :type => Hydrus::RoleMetadataDS,
    :label => 'Role Metadata',
    :control_group => 'M')

  # @return [String] the identifier of the object's depositor
  def item_depositor_id
    roleMetadata.item_depositor.person.identifier.first
  end
  
  def date_created
    descMetadata.date_created.try(:first)
  end
    

  # Note: currently all items of of type :item. In the future,
  # the calling code can pass in the needed value.
  def self.create(collection_pid, user, itype = Hydrus::Application.config.default_item_type)
    # Make sure user can create items in the parent collection.
    coll = Hydrus::Collection.find(collection_pid)
    raise "#{cannot_do_message(:create)}\nCollection '#{collection_pid}' is not open" unless coll.is_open()
    raise "#{cannot_do_message(:create)}\nUser '#{user}' cannot create items in #{coll} #{collection_pid} according to APO #{coll.apo.pid}" unless Hydrus::Authorizable.can_create_items_in(user, coll)
    # Create the object, with the correct model.
    dor_item = Hydrus::GenericObject.register_dor_object(user, 'item', coll.apo_pid)
    item     = Hydrus::Item.find(dor_item.pid)
    item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
    item.assert_content_model
    # Add the Item to the Collection.
    item.collections << coll
    # Create default rightsMetadata from the collection
    #item.rightsMetadata.content = coll.rightsMetadata.ng_xml.to_s
    # Set the item_type, and add some Hydrus-specific info to identityMetadata.
    item.set_item_type(itype)

    # Add roleMetadata with current user as hydrus-item-depositor.
    item.roleMetadata.add_person_with_role(user, 'hydrus-item-depositor')
    # Set default license, embargo, and visibility.
    item.license = coll.license
    if coll.embargo_option == 'fixed'
      item.embargo_date = HyTime.date_display(item.end_of_embargo_range)
    end
    vov = coll.visibility_option_value
    item.visibility = vov == 'stanford' ? vov : 'world'
    item.terms_of_use = Hydrus::GenericObject.stanford_terms_of_use
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
    item.send_new_deposit_email_notification
    return item
  end

  # Publish the Item directly, bypassing human approval.
  def publish_directly
    raise "#{cannot_do_message(:publish_directly)}\nItem is not publishable" unless is_publishable()
    complete_workflow_step('submit')
    send_item_deposit_email_notification
    do_publish()
  end

  # A method to implement the steps steps associated with publishing an Item.
  # Called by publish_directly() and approve(), not by the controller.
  def do_publish
    # Set publish times: latest and initial.
    tm = HyTime.now_datetime
    self.submitted_for_publish_time = tm
    self.initial_submitted_for_publish_time = tm if is_initial_version()
    # Set label and title.
    t = title()
    identityMetadata.objectLabel = t
    self.label = t
    datastreams['DC'].title = [t]
    # Update object status and advance workflow.
    self.object_status = 'published'
    complete_workflow_step('approve')
    # Version, events, and assembly pipeline.
    close_version() unless is_initial_version()
    events.add_event('hydrus', @current_user, "Item published: #{version_tag()}")
    start_common_assembly()
  end

  # Submit the Item for approval by a reviewer.
  # This method handles the initial submission, not resubmissions.
  def submit_for_approval
    raise "#{cannot_do_message(:submit_for_approval)}\nItem is not submittable" unless is_submittable_for_approval()
    self.submit_for_approval_time   = HyTime.now_datetime
    self.object_status = 'awaiting_approval'
    complete_workflow_step('submit')
    events.add_event('hydrus', @current_user, "Item submitted for approval")
    send_deposit_review_email_notification
  end

  # Approve the Item.
  def approve
    raise "#{cannot_do_message(:approve)}\nItem is not approvable" unless is_approvable()
    hydrusProperties.remove_nodes(:disapproval_reason)
    events.add_event('hydrus', @current_user, "Item approved")
    do_publish()
  end

  # Disapprove the Item -- return it for further editing.
  # Expects to receive a hash with a 'reason' key.
  def disapprove(reason)
    raise "#{cannot_do_message(:disapprove)}\nItem is not disapprovable" unless is_disapprovable()
    self.object_status      = 'returned'
    self.disapproval_reason = reason
    events.add_event('hydrus', @current_user, "Item returned")
    send_object_returned_email_notification
  end

  # Resubmits an object after it was disapproved/returned.
  def resubmit
    raise "#{cannot_do_message(:resubmit)}\nItem is not resubmittable" unless is_resubmittable()
    self.submit_for_approval_time   = HyTime.now_datetime
    self.object_status = 'awaiting_approval'
    hydrusProperties.remove_nodes(:disapproval_reason)
    events.add_event('hydrus', @current_user, "Item resubmitted for approval")
    send_deposit_review_email_notification
  end

  # Opens a new version of the Item.
  # Notes:
  #   - After an Item is published, in order to make further edits, the
  #     user must open a new version.
  #   - Options used when opening versions during Hydrus remediations:
  #       :significance
  #       :description
  #       :is_remediation
  #   - Other options:
  #       :no_super   Used to prevent super() during testing.
  def open_new_version(opts = {})
    raise "#{cannot_do_message(:open_new_version)}\nItem is not accessioned" unless is_accessioned()
    # Store the time when the object was initially published.
    self.initial_publish_time = publish_time() if is_initial_version
    # Call the dor-services method, with a couple of Hydrus-specific options.
    super(:assume_accessioned => should_treat_as_accessioned(), :create_workflows_ds => false)
    # Set some version metadata that the Hydrus app uses.
    sig  = opts[:significance] || :major
    desc = opts[:description]  || ''
    versionMetadata.update_current_version(:description => desc, :significance => sig)
    # Varying behavior: remediations vs ordinary user edits.
    if opts[:is_remediation]
      # Just log the event.
      events.add_event('hydrus', 'admin', "Object remediated")
    else
      self.version_started_time = HyTime.now_datetime
      # Put the object back in the draft state.
      self.object_status = 'draft'
      uncomplete_workflow_steps()
      # Store a copy of the current license and visibility.
      # We use those values when enforcing subsequent-version validations.
      self.prior_license = license
      self.prior_visibility = visibility
      # Log the event.
      events.add_event('hydrus', @current_user, "New version opened")
    end
  end

  # Closes the current version of the Item.
  # This occurs when an Item is published, unless it was the initial version.
  # See do_publish(), where all of the Hydrus-specific work is done; here
  # we simply invoke the dor-services method.
  def close_version(opts = {})
    raise "#{cannot_do_message(:close_version)}\nItem is initial version" if is_initial_version(:absolute => true)
    # We want to start accessioning only if ...
    sa = !! opts[:is_remediation]              # ... we are running a remediation and
    sa = false if should_treat_as_accessioned  # ... we are not in development or test
    super(:version_num => version_id, :start_accession => sa)
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

  def send_new_deposit_email_notification
    return if recipients_for_new_deposit_emails.blank?
    email = HydrusMailer.send("new_deposit", :object => self)
    email.deliver_now unless email.to.blank?
  end

  def send_item_deposit_email_notification
    return if recipients_for_item_deposit_emails.blank?
    email = HydrusMailer.send("item_deposit", :object => self)
    email.deliver_now unless email.to.blank?
  end

  def send_deposit_review_email_notification
    return if recipients_for_review_deposit_emails.blank?
    email = HydrusMailer.send("new_item_for_review", :object => self)
    email.deliver_now unless email.to.blank?
  end

  # get the friendly display name for the current item type
  def item_type_for_display
    typ=self.class.item_types.key(self.item_type)
    typ.blank? ? self.class.item_types.key(Hydrus::Application.config.default_item_type) : typ
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

  # Returns true if the item is publishable: must be valid and must
  # have the correct object_status.  Any item requiring human approval is not publishable, it is only approvable
  def is_publishable_directly
    return false if to_bool(requires_human_approval)
    return (validate! ? is_draft : false)
  end


  # Returns true if the object is ready for common assembly.
  # It's not strictly necessary to involve validate!, but it provides extra insurance.
  def is_assemblable
    return false unless is_published
    return validate!
  end

  # Returns true only if the Item is unpublished and is on the first version.
  def is_destroyable
    return not(is_published) && is_initial_version
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

  # you must have at least one non-blank contributor
  def contributors_not_all_blank
    if (contributors.all? {|contributor| contributor.name.blank?})
      errors.add(:contributors, "must be entered")
    end
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

  # the date_created must be of format YYYY or YYYY-MM or YYYY-MM-DD
  def ensure_date_created_format
    if not date_created =~ /^\d{4}$/ and not date_created =~ /^\d{4}-\d{2}$/ and not date_created =~ /^\d{4}-\d{2}-\d{2}$/
      errors.add(:date_created, 'Incorrect date format')
    end
  end

  # method that catches the user checking a box on the item edit page which triggers terms of deposit acceptance
  def terms_of_deposit_checkbox=(value)
    accept_terms_of_deposit(@current_user) if value
  end

  # Accepts terms of deposit for the given user.
  # At the item level we store true/false.
  # At the colleciton level we store user name and datetime.
  def accept_terms_of_deposit(user)
    raise "#{cannot_do_message(:accept_terms_of_deposit)}\nUser #{user} cannot edit item" unless Hydrus::Authorizable.can_edit_item(user, self)
    self.accepted_terms_of_deposit = "true"
    collection.accept_terms_of_deposit(user, HyTime.now_datetime, self)
    events.add_event('hydrus', user, 'Terms of deposit accepted')
  end

  # Returns true if the Item's embargo_date can be changed, based on the
  # Collection setting, the version, and whether the Item has an embargo_date.
  def embargo_can_be_changed
    # Collection must allow it.
    return false unless collection.embargo_option == 'varies'
    # Behavior varies by version.
    if is_initial_version
      return true
    else
      # In subsequent versions, Item must
      #   - have an existing embargo
      #   - that has a max embargo date some time in the future
      return false unless is_embargoed
      return HyTime.now < end_of_embargo_range.to_datetime
    end
  end

  # Return's true if the user can modify the Item visibility.
  #   - Collection must allow it.
  #   - Initial version: anything goes.
  #   - Subsequent versions: visibility cannot be reduced from world to stanford.
  def visibility_can_be_changed
    return false unless collection.visibility_option == 'varies'
    return true  if is_initial_version
    return false if prior_visibility == 'world'
    return true
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
  #                     nil            # Ditto.
  #
  #     'visibility' => 'world'
  #                     'stanford'
  #                     nil            # Ditto.
  #
  # Given that hash, we call the embargo_date and visibility
  # setters. The UI invovkes this combined setter (not the individual
  # setters), because we want to ensure that the individual setters
  # are called in the desired order. This is necessary because the
  # visibility setter needs to know the Item's embargo status.
  def embarg_visib=(opts)
    e  = opts['embargoed']
    d  = opts['date']
    v  = opts['visibility'] || visibility.first
    dt = to_bool(e) ? d : ''
    self.embargo_date = dt unless e.nil?
    self.visibility   = v
  end

  # Returns true if the Item is embargoed.
  def is_embargoed
    return not(embargo_date.blank?)
  end

  # Returns the embargo date from the embargoMetadata, not the rightsMetadata.
  # We don't use the latter because it is a convenience copy used by the PURL app.
  # Switched to returning '' rather than nil, because we were getting extraneous
  # editing events related to embargo_date (old value of '' and new value of nil).
  def embargo_date
    ed = embargoMetadata ? embargoMetadata.release_date : ''
    ed = '' if ed.nil?
    return ed
  end

  # Sets the embargo date in both embargoMetadata and rightsMetadata.
  # The new value is assumed to be expressed in the local time zone.
  # If the new date is blank, nil, or not parsable as a datetime,
  # the embargoMetadata datastream is deleted.
  #
  # Notes:
  #   - We do not call this directly from the UI. Instead, the embarg_visib
  #     setter is used (see its notes).
  #   - If the argument is not parsable as a datetime, we set an instance
  #     variable, which we use latter (during validations) to tell the
  #     user that the embargo date was malformed. This awkwardness could
  #     be avoided if we simplify the UI, removing the embargo radio button.
  def embargo_date= val
    if HyTime.is_well_formed_datetime(val)
      ed = HyTime.datetime(val, :from_localzone => true)
    elsif val.blank?
      ed = nil
    else
      @embargo_date_was_malformed = true
      return
    end
    if ed.blank?
      # Note: we must removed the embargo date from embargoMetadata (even
      # though we also delete the entire datastream), because the former
      # happens right away (which we need) and the latter appears to
      # happen later (maybe during save).
      rightsMetadata.remove_embargo_date
      embargoMetadata.remove_embargo_date
      embargoMetadata.delete
    else
      self.rmd_embargo_release_date = ed
      embargoMetadata.release_date  = DateTime.parse(ed)
      embargoMetadata.status        = 'embargoed'
    end
  end

  # Adds an embargo_date validation error if the prior call to
  # the embargo_date setter determined that the date supplied by
  # the user had in invalid format.
  def embargo_date_is_well_formed
    return unless @embargo_date_was_malformed
    msg = "must be in #{HyTime::DATE_PICKER_FORMAT} format"
    errors.add(:embargo_date, msg)
  end

  # Validates that the embargo date set by the user falls within the allowed range.
  # Note: the embargo date picker does not offer the user the choice of setting a
  # date in the past; nonetheless, it is possible for a valid object to have a
  # past embargo date, because the nightly job that removes embargoMetadata
  # once the date has passed might not have run yet.
  def embargo_date_in_range
    return unless is_embargoed
    b  = beginning_of_embargo_range.to_datetime
    e  = end_of_embargo_range.to_datetime
    dt = embargo_date.to_datetime
    unless (b <= dt and dt <= e)
      b = HyTime.date_display(b)
      e = HyTime.date_display(e)
      errors.add(:embargo_date, "must be in the range #{b} through #{e}")
    end
  end

  # Returns a datetime string for the start of the embargo range.
  # Has item ever been published?
  #   - No:  returns now.
  #   - Yes: returns time of initial submission for publication.
  # Note: If the item has been published this method can return
  # dates in the past; for that reason, we do not use this method
  # to definie the beginning date allowed by the embargo date picker.
  def beginning_of_embargo_range
    return initial_submitted_for_publish_time || HyTime.now_datetime
  end

  # Parses embargo_terms (eg, "2 years") into its number and time-unit parts.
  # Uses those parts to add a time increment (eg 2.years) to the beginning
  # of the embargo range. Returns that result as a datetime string.
  def end_of_embargo_range
    n, time_unit = collection.embargo_terms.split
    dt = beginning_of_embargo_range.to_datetime + n.to_i.send(time_unit)
    return HyTime.datetime(dt)
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
      # And we clear our read access in rightsMetadata and add an explicit <none/> block.
      rightsMetadata.deny_read_access
    else
      # Otherwise, just set access info in rightsMetadata.
      # The embargoMetadata should not exist at this point.
      rightsMetadata.update_access_blocks(val)
    end
  end

  def files
    Hydrus::ObjectFile.where(pid: pid).order('weight ASC,label ASC,file ASC')
  end

  def strip_whitespace
    strip_whitespace_from_fields [:preferred_citation,:title,:abstract,:contact]
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

  # Returns the Item's contributors, as an array of Hydrus::Contributor objects.
  def contributors
    return descMetadata.contributors
  end

  def dates
    h={}
    #raise descMetadata.ng_xml.to_s
    h[:date_created] = single_date? ? descMetadata.date_created : ''
    #raise descMetadata.date_created.inspect
    begin
      h[:date_created_approximate] = (descMetadata.originInfo.dateCreated.respond_to?(:nodeset) and single_date?) ? descMetadata.originInfo.dateCreated.nodeset.first['qualifier'] == "approximate" : false
    rescue
      h[:date_created_approximate] = false
    end
    h[:date_range_start] = descMetadata.originInfo.date_range_start ? descMetadata.originInfo.date_range_start : ''
    h[:date_range_start_approximate] = descMetadata.originInfo.date_range_start.first ? descMetadata.ng_xml.search("//mods:originInfo/mods:dateCreated[@point='start']", 'mods' => 'http://www.loc.gov/mods/v3').first['qualifier'] == "approximate" : false
    h[:date_range_end] = descMetadata.originInfo.date_range_end ? descMetadata.originInfo.date_range_end : ''
    h[:date_range_end_approximate] = descMetadata.originInfo.date_range_end.first ? descMetadata.ng_xml.search("//mods:originInfo/mods:dateCreated[@point='end']", 'mods' => 'http://www.loc.gov/mods/v3').first['qualifier'] == "approximate" : false
    h[:undated] = undated?
    h[:range] = date_range?
    h[:single] = single_date?
    h
  end
  def dates=(h)
    descMetadata.remove_nodes(:date_created)
    if h[:date_type] == 'single'
      descMetadata.originInfo.dateCreated = h[:date_created]
      #the if respond to is for initial item creation
      if descMetadata.originInfo.dateCreated and descMetadata.originInfo.dateCreated.respond_to? :nodeset
        descMetadata.originInfo.dateCreated.nodeset.first['qualifier'] = "approximate" if h[:date_created_approximate]
        descMetadata.originInfo.dateCreated.nodeset.first['keyDate']="yes"
        descMetadata.originInfo.dateCreated.nodeset.first['encoding']="w3cdtf"
      end
    end
    if h[:date_type] == 'range'
      descMetadata.originInfo.date_range_start = h[:date_start]
      if descMetadata.originInfo.date_range_start.respond_to? :nodeset
        descMetadata.originInfo.date_range_start.nodeset.first['qualifier'] = "approximate" if h[:date_range_start_approximate] == "hi"
        descMetadata.originInfo.date_range_start.nodeset.first['keyDate']="yes"
        descMetadata.originInfo.date_range_start.nodeset.first['encoding']="w3cdtf"
      end
      descMetadata.originInfo.date_range_end = h[:date_range_end]
      if descMetadata.originInfo.date_range_end.respond_to? :nodeset
        descMetadata.originInfo.date_range_end.nodeset.first['qualifier'] = "approximate" if h[:date_range_end_approximate] == "hi"
        descMetadata.originInfo.date_range_end.nodeset.first['encoding']="w3cdtf"
      end
    end
    if h[:date_type] == 'undated'
      descMetadata.originInfo.dateCreated='Undated'
    end
  end
  #the date(s) rendered for display
  def date_display
    disp = ''
    if date_range?
      start_only = true if dates[:date_range_start_approximate] and not dates[:date_range_end_approximate]
      end_only =  true if dates[:date_range_end_approximate] and not dates[:date_range_start_approximate]
      both = true if dates[:date_range_start_approximate] and dates[:date_range_end_approximate]
      disp += '[ca. ' if start_only or both
      disp += "#{dates[:date_range_start].first}"
      disp += ']' if start_only
      disp += ' to ' unless both
      disp += ' - ' if both
      disp += '[' if end_only
      disp += 'ca. ' if end_only or both
      disp += "#{dates[:date_range_end].first}"
      disp += ']' if end_only or both
      return disp
    else
      if single_date?
        disp += '[ca. ' if dates[:date_created_approximate]
        disp += "#{dates[:date_created].length > 0 ? dates[:date_created].first : ''}"
        disp += ']' if dates[:date_created_approximate]
        return disp
      else
        return 'Undated'
      end
    end
  end
  def date_range?
    descMetadata.originInfo.date_range_start.length == 1
  end

  def single_date?
    !date_range? and !undated?
  end

  def undated?
    !date_range? and date_created == 'Undated'
  end

  #check whether a string that we think is a date matches our expected date format
  def valid_date_string? str
    str =~ /^\d{4}$/ or str =~ /^\d{4}-\d{2}$/ or str =~ /^\d{4}-\d{2}-\d{2}$/
  end

  def has_specified_a_valid_date
    if single_date?
      if not valid_date_string? date_created
        errors.add(:dates, 'Incorrect date format or missing date.')
      end
    else
      if date_range?
        if not valid_date_string?(descMetadata.originInfo.date_range_start.first) or not valid_date_string?(descMetadata.originInfo.date_range_end.first)
          errors.add(:dates, 'Incorrect date formats or missing dates.')
        end
      else
        if not undated?
          errors.add(:dates, 'No date type selected.')
        end
      end
    end
  end
  # This is the setter called from the Item edit UI.
  # Takes a params-style hash like this, with the inner hashes
  # having the name and role_key for the Item's contributors:
  #   {
  #     "0" => {"name"=>"AAA", "role_key"=>"corporate_author"},
  #     "1" => {"name"=>"BBB", "role_key"=>"personal_author"},
  #   }
  #
  # Uses that hash to rewrite all <name> nodes in the descMetadata.
  def contributors=(h)
    descMetadata.remove_nodes(:name)
    h.values.each { |c|
      insert_contributor(c['name'], c['role_key'])
    }
  end

  # Takes a Contributor name and role_key.
  # Uses that role_key to lookup the corresponding name_type and role.
  # Uses those to add a <name> node to the descMetadata.
  def insert_contributor(name = '', role_key = nil)
    typ, role = Hydrus::Contributor.lookup_with_role_key(role_key)
    descMetadata.insert_contributor(typ, name, role)
  end

  def self.discovery_roles
    return {
      "everyone"      => "world",
      "Stanford only" => "stanford",
    }
  end

  # the users who will receive email notifications when an item is published or submitted for approval
  def recipients_for_item_deposit_emails
    self.item_depositor_id
  end

  # the users who will receive email notifications when a new item is created
  def recipients_for_new_deposit_emails
    managers=apo.persons_with_role("hydrus-collection-manager").to_a
    managers.delete(self.item_depositor_id)
    return managers.join(', ')
  end

  # the users who will receive email notifications when an item is submitted for review
  def recipients_for_review_deposit_emails
    managers=(
      apo.persons_with_role("hydrus-collection-manager") +
      apo.persons_with_role("hydrus-collection-reviewer")
    ).to_a
    managers.delete(self.item_depositor_id)
    return managers.join(', ')
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
  # By default "initial version" is user-centric and ignores administrative
  # version changes (for example, those run during remediations). Thus,
  # version_tags like v1.0.0 and v1.0.3 would pass the test.
  # If the :absolute option is true, the test passes only if it's truly
  # the first version.
  def is_initial_version(opts = {})
    return true if current_version == '1'
    return false if opts[:absolute]
    return version_tag =~ /\Av1\.0\./ ? true : false
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

  # Deletes an Item.
  def delete
    raise "#{cannot_do_message(:delete)}\nItem is not destroyable" unless is_destroyable
    d = parent_directory
    FileUtils.rm_rf(d)            # Uploaded files.
    files.each { |f| f.destroy }  # The corresponding DB entries.
    delete_hydrus_workflow        # Hydrus workflow.
    super                         # Fedora object and SOLR entries.
  end

end

class Hydrus::ItemWithoutCollectionError < StandardError
end
