class Hydrus::Item < Hydrus::GenericObject

  include Hydrus::Responsible
  include Hydrus::Contentable
  include Hydrus::Versionable
  include Hydrus::Embargoable

  REQUIRED_FIELDS = [:title, :abstract, :contact, :keywords, :version_description, :date_created]

  define_attribute_method :files

  after_validation :strip_whitespace

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
  validates :files, :at_least_one => true,         :if => :should_validate
  validate  :must_accept_terms_of_deposit,         :if => :should_validate
  validate  :must_review_release_settings,         :if => :should_validate

  validate  :check_version, :if => :license_changed?
  validate  :ensure_date_created_format,          :if => :should_validate

  # During subsequent versions the user is allowed to change the license,
  # but only if the new version is designated as a major version change.
  def check_version
    return if is_initial_version or version_significance == :major
    msg = "must be 'major' if license is changed" if license_changed?
    errors.add(:version, msg) unless msg.blank?
  end

  has_metadata(
    :name => "roleMetadata",
    :type => Hydrus::RoleMetadataDS,
    :label => 'Role Metadata',
    :control_group => 'M')

  setup_delegations(
    # [:METHOD_NAME,               :uniq, :at... ]
    "descMetadata" => [
      [:preferred_citation,        true   ],
      [:date_created,              true   ],
      [:related_citation,          false  ],
    ],
    "roleMetadata" => [
      [:item_depositor_id,         true,  :item_depositor, :person, :identifier],
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

  # Note: currently all items of of type :item. In the future,
  # the calling code can pass in the needed value.
  def self.create(collection_pid, user, itype = Hydrus::Application.config.default_item_type)
    # Make sure user can create items in the parent collection.
    coll = Hydrus::Collection.find(collection_pid)
    cannot_do(:create) unless coll.is_open()
    cannot_do(:create) unless Hydrus::Authorizable.can_create_items_in(user, coll)
    # Create the object, with the correct model.
    item = Hydrus::GenericObject.register_dor_object(:user => user, :object_type => 'item', :collection => coll, :admin_policy => coll.apo_pid)
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
    item.terms_of_use = Hydrus.stanford_terms_of_use
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
    cannot_do(:publish_directly) unless is_publishable()
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
    cannot_do(:submit_for_approval) unless is_submittable_for_approval()
    self.submit_for_approval_time   = HyTime.now_datetime
    self.object_status = 'awaiting_approval'
    complete_workflow_step('submit')
    events.add_event('hydrus', @current_user, "Item submitted for approval")
    send_deposit_review_email_notification
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
    send_object_returned_email_notification
  end

  # Resubmits an object after it was disapproved/returned.
  def resubmit
    cannot_do(:resubmit) unless is_resubmittable()
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
    cannot_do(:open_new_version) unless is_accessioned()
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
    cannot_do(:close_version) if is_initial_version(:absolute => true)
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
    email.deliver unless email.to.blank?
  end

  def send_item_deposit_email_notification
    return if recipients_for_item_deposit_emails.blank?
    email = HydrusMailer.send("item_deposit", :object => self)
    email.deliver unless email.to.blank?
  end
  
  def send_deposit_review_email_notification
    return if recipients_for_review_deposit_emails.blank?
    email = HydrusMailer.send("new_item_for_review", :object => self)
    email.deliver unless email.to.blank?
  end

  # get the friendly display name for the current item type
  def item_type_for_display
    Hydrus.item_types.fetch(self.item_type, Hydrus.item_types[Hydrus.default_item_type])
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

  # Returns true only if the Item is unpublished.
  def is_destroyable
    return not(is_published)
  end

  # Returns the Item's Collection.
  def collection
    @collection ||= collections.first       # Get all collections.
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
    cannot_do(:accept_terms_of_deposit) unless Hydrus::Authorizable.can_edit_item(user, self)
    self.accepted_terms_of_deposit = "true"
    collection.accept_terms_of_deposit(user, HyTime.now_datetime, self)
    events.add_event('hydrus', user, 'Terms of deposit accepted')
  end

  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight ASC,label ASC,file ASC')
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

  # Deletes an Item.
  def destroy
    cannot_do(:delete) unless is_destroyable
    d = parent_directory
    FileUtils.rm_rf(d)            # Uploaded files.
    files.each { |f| f.destroy }  # The corresponding DB entries.
    delete_hydrus_workflow        # Hydrus workflow.
    super                         # Fedora object and SOLR entries.
  end

end

class Hydrus::ItemWithoutCollectionError < StandardError
end
