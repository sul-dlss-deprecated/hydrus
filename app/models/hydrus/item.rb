class Hydrus::Item < Hydrus::GenericObject

  include Hydrus::Responsible
  extend  Hydrus::Delegatable

  after_validation :strip_whitespace    
  
  validate :enforce_collection_is_open, :on => :create
  validates :actors, :at_least_one=>true, :if => :should_validate
  validates :files, :at_least_one=>true, :if => :should_validate
  validate  :must_accept_terms_of_deposit, :if => :should_validate
  validate  :must_review_release_settings, :if => :should_validate
  validate  :embargo_date_is_correct_format, :if => :should_validate
  validate :embargo_date_in_range, :if => :should_validate

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
    # Create the object, with the correct model.
    coll     = Hydrus::Collection.find(collection_pid)
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
    # Set object status.
    item.object_status = 'draft'
    item.deposit_time  = Time.now.in_time_zone.to_s
    # Add event.
    item.events.add_event('hydrus', user, 'Item created')
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
    item.save(:no_edit_logging => true)
    return item
  end

  # Publish the Item directly, bypassing human approval.
  def publish_directly
    cannot_do(:publish_directly) unless is_publishable()
    self.submit_time = Time.now.in_time_zone.to_s
    complete_workflow_step('submit')
    do_publish()
  end

  # A method to implement the steps steps associated with publishing an Item.
  # Called by publish_directly() and approve(), not by the controller.
  def do_publish
    t = title()
    identityMetadata.objectLabel = t
    self.label                   = t
    self.object_status = 'published'
    complete_workflow_step('approve')
    events.add_event('hydrus', @current_user, "Item published")
    start_common_assembly()
  end

  # Submit the Item for approval by a reviewer.
  # This method handles the initial submission, not resubmissions.
  def submit_for_approval
    cannot_do(:submit_for_approval) unless is_submittable_for_approval()
    self.object_status = 'awaiting_approval'
    self.submit_time   = Time.now.in_time_zone.to_s
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
    self.object_status = 'awaiting_approval'
    hydrusProperties.remove_nodes(:disapproval_reason)
    events.add_event('hydrus', @current_user, "Item resubmitted for approval")
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
      users=coll.users_accepted_terms_of_deposit 
      if users && users.keys.include?(user) 
        return (Time.now.in_time_zone - 1.year) > coll.users_accepted_terms_of_deposit[user].to_datetime
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

  def base_file_directory
    f = File.join(Rails.root, "public", Hydrus::Application.config.file_upload_path)
    DruidTools::Druid.new(pid, f).path
  end

  def content_directory
    File.join(base_file_directory, "content")
  end

  def metadata_directory
    File.join(base_file_directory, "metadata")
  end

  def update_content_metadata
    xml = create_content_metadata
    if !xml.strip.blank? && DruidTools::Druid.valid?(self.pid)
      # write xml to a file
      Dir.mkdir(metadata_directory) unless File.directory? metadata_directory
      f = File.join(metadata_directory, 'contentMetadata.xml')
      File.open(f, 'w') { |fh| fh.puts xml }
    end
    datastreams['contentMetadata'].content = xml
  end

  def create_content_metadata
    objects = files.collect { |file|
      Assembly::ObjectFile.new(file.current_path, :label=>file.label)
    }
    return '' if objects.empty?
    return Assembly::ContentMetadata.create_content_metadata(
      :druid            => pid,
      :objects          => objects,
      :add_file_attributes => true,
      :style            => Hydrus::Application.config.cm_style,
      :file_attributes  => Hydrus::Application.config.cm_file_attributes,
      :include_root_xml => false)
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
  
  # accepts terms of deposit for the given user
  def accept_terms_of_deposit(user)
    self.accepted_terms_of_deposit="true"
    self.collection.accept_terms_of_deposit(user,Time.now.in_time_zone) # update the collection level user acceptance list
    events.add_event('hydrus', user, 'Terms of deposit accepted')
  end
  
  def beginning_of_embargo_range
    submit_time ? Date.parse(submit_time).strftime("%m/%d/%Y") :
                  Date.today.strftime("%m/%d/%Y")
  end

  def end_of_embargo_range
    length = collection.embargo_terms
    number = length.split(" ").first.to_i
    increment = length.split(" ").last
    # number.send(increment) is essentially doing 6.months, 2.years, etc.
    # This works because rails extends Fixnum to respond to things like #months, #years etc.
    (Date.strptime(beginning_of_embargo_range, "%m/%d/%Y") + number.send(increment)).strftime("%m/%d/%Y")
  end

  def embargo_date_is_correct_format
   return unless under_embargo?
   begin
     Date.strptime(embargo_date, "%m/%d/%Y").to_s
   rescue ArgumentError
      errors.add(:embargo_date, 'must be a valid date')
   end
  end

  def embargo
    self.embargo_date.blank? ? 'immediate' : 'future' 
  end  

  def embargo=(val)
    self.embargo_date='' if val == 'immediate' 
  end
  
  def under_embargo?
    embargo=='future' && !collection.blank? && collection.embargo_option == "varies"
  end

  def embargo_date_in_range
    if under_embargo? and embargo == "future" and !embargo_date.blank?
      unless (Date.strptime(beginning_of_embargo_range, "%m/%d/%Y")...Date.strptime(end_of_embargo_range, "%m/%d/%Y")).include?(Date.strptime(embargo_date, "%m/%d/%Y"))
        errors.add(:embargo_date, "must be in the date range #{beginning_of_embargo_range} - #{end_of_embargo_range}")
      end
    end
  end

  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight')  # coming from the database
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

end

class Hydrus::ItemWithoutCollectionError < StandardError
end

