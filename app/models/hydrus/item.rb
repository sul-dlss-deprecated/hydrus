class Hydrus::Item < Hydrus::GenericObject

  include Hydrus::EmbargoMetadataDsExtension
  include Hydrus::Responsible
  extend  Hydrus::Delegatable

  after_validation :strip_whitespace

  attr_accessor :embargo
  
  validate :collection_is_open, :on => :create
  validates :actors, :at_least_one=>true, :if => :should_validate
  validates :files, :at_least_one=>true, :if => :should_validate
  validate  :must_accept_terms_of_deposit, :if => :should_validate
  validate  :must_review_release_settings, :if => :should_validate
  # validate  :embargo_date_is_correct_format # TODO
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

  has_metadata(
    :name => "rightsMetadata",
    :type => Hydrus::RightsMetadataDS,
    :label => 'Rights Metadata',
    :control_group => "M")

  def self.create(collection_pid, user)
    # Create the object, with the correct model.
    coll     = Hydrus::Collection.find(collection_pid)
    dor_item = Hydrus::GenericObject.register_dor_object(user, 'item', coll.apo_pid)
    item     = dor_item.adapt_to(Hydrus::Item)
    item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
    item.assert_content_model
    # Add the Item to the Collection.
    item.add_to_collection(coll.pid)
    # Add some Hydrus-specific info to identityMetadata.
    item.augment_identity_metadata(:dataset)  # TODO: hard-coded value.
    # Add roleMetadata with current user as hydrus-item-depositor.
    item.roleMetadata.add_person_with_role(user, 'hydrus-item-depositor')
    # Set object status.
    item.object_status = 'draft'
    # Add event.
    item.events.add_event('hydrus', user, 'Item created')
    # Check to see if this user needs to agree again for this new item, if not, indicate agreement has already occured automatically
    if item.requires_terms_acceptance(user.to_s,coll) == false
      item.accepted_terms_of_deposit="true"
      item.events.add_event('hydrus', user, 'Terms of deposit accepted due to previous item acceptance in collection')
    else
      item.accepted_terms_of_deposit="false"      
    end
    # Save and return.
    item.save(:no_edit_logging => true)
    return item
  end

  # Resubmits an object by resetting the reason in the hydrusProperties datastream
  def resubmit(value = nil)
    events.add_event('hydrus', @current_user, "Item resubmitted for approval")
    hydrusProperties.remove_nodes(:disapproval_reason)
    self.object_status = 'awaiting_approval'
  end
  
  # Publish the Item.
  def publish(value = nil)
    # At the moment of publication, we refresh various titles.
    identityMetadata.objectLabel = title
    self.label                   = title # The label in Fedora's foxml:objectProperties.
    self.save
    # Advance workflow to record that the object has been published.
    # And auto-approve, unless human review is needed.
    rha                = to_bool(requires_human_approval)
    s                  = 'submit'
    self.object_status = rha ? 'awaiting_approval'      : 'published'
    msg                = rha ? 'submitted for approval' : 'published'
    complete_workflow_step(s)
    approve() unless rha
    events.add_event('hydrus', @current_user, "Item #{msg}")
  end

  # indicates if this item has an accepted terms of deposit, or if the supplied user (logged in user) has accepted a terms of deposit for another item in this collection within the last year
  # you can pass in a specific collection to check, if not specified, defaults to this item's collection (useful when creating new items)
  def requires_terms_acceptance(user,coll=self.collection)
    if to_bool(accepted_terms_of_deposit) # if this item has previously been accepted, no further checks are needed
      return false 
    else
      # if this item has not been accepted, let's look at the collection
      users=coll.users_accepted_terms_of_deposit # get the users who have accepted the terms of deposit for any other items in this collection
      if users && users.keys.include?(user) # if there are users, find out if the supplied user is one of them
        return (Time.now - 1.year) > coll.users_accepted_terms_of_deposit[user].to_datetime # if so, have agreed within the last year?
      else
        return true
      end
    end
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
    
  #################################
  # methods used to build sidebar

  def files_uploaded?
    validate! ? true : !errors.keys.include?(:files)
  end

  def terms_of_deposit_accepted?
    validate! ? true : !errors.keys.include?(:terms_of_deposit)
  end
  
  def reviewed_release_settings?
    validate! ? true : !errors.keys.include?(:release_settings)    
  end

  ###########################
  
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
      :style            => Hydrus::Application.config.cm_style,
      :file_attributes  => Hydrus::Application.config.cm_file_attributes,
      :include_root_xml => false)
  end

  # Returns true only if the Item has an open Collection.
  def collection_is_open
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
    self.collection.accept_terms_of_deposit(user,Time.now) # update the collection level user acceptance list
    events.add_event('hydrus', user, 'Terms of deposit accepted')
  end
  
  # Returns the Item's license, if present.
  # Otherwise, return's the Collection's license.
  def license *args
    lic = rightsMetadata.use.machine(*args).first
    return lic unless lic.blank?
    return collection.license
  end

  def license= val
    rightsMetadata.remove_nodes(:use)
    Hydrus::Collection.licenses.each do |type,licenses|
      licenses.each do |license|
        if license.last == val
          # I would like to do this type_attribute part better.
          # Maybe infer the insert method and call send on rightsMetadata.
          type_attribute = Hydrus::Collection.license_commons[type]
          if type_attribute == "creativeCommons"
            rightsMetadata.insert_creative_commons
          elsif type_attribute == "openDataCommons"
            rightsMetadata.insert_open_data_commons
          end
          rightsMetadata.use.machine = val
          rightsMetadata.use.human = license.first
        end
      end
    end
  end

  def visibility *args
    groups = []
    if embargo_date
      if embargoMetadata.release_access_node.at_xpath('//access[@type="read"]/machine/world')
        groups << "world"
      else
        node = embargoMetadata.release_access_node.at_xpath('//access[@type="read"]/machine/group')
        groups << node.text if node
      end
    else
      (rightsMetadata.read_access.machine.group).collect{|g| groups << g}
      (rightsMetadata.read_access.machine.world).collect{|g| groups << "world" if g.blank?}
    end
    groups
  end

  def visibility= val
    embargoMetadata.release_access_node = Nokogiri::XML(generic_release_access_xml) unless embargoMetadata.ng_xml.at_xpath("//access")
    if embargo == "immediate"
      embargoMetadata.release_access_node = Nokogiri::XML("<releaseAccess/>")
      rightsMetadata.remove_embargo_date
      embargoMetadata.remove_embargo_date
      update_access_blocks(rightsMetadata, val)
    elsif embargo == "future"
      rightsMetadata.remove_world_read_access
      rightsMetadata.remove_all_group_read_nodes
      update_access_blocks(embargoMetadata, val)
      embargoMetadata.release_date = Date.strptime(embargo_date, "%m/%d/%Y")
    end
  end

  def embargo_date *args
    date = (rightsMetadata.read_access.machine.embargo_release_date *args).first
    Date.parse(date).strftime("%m/%d/%Y") unless date.blank?
  end

  def embargo_date= val
    date = val.blank? ? "" : Date.strptime(val, "%m/%d/%Y").to_s
    (rightsMetadata.read_access.machine.embargo_release_date= date) unless date.blank?
  end

  def beginning_of_embargo_range
    submit_time ? Date.parse(submit_time).strftime("%m/%d/%Y") :
                  Date.today.strftime("%m/%d/%Y")
  end

  def end_of_embargo_range
    length = collection.apo.embargo
    number = length.split(" ").first.to_i
    increment = length.split(" ").last
    # number.send(increment) is essentially doing 6.months, 2.years, etc.
    # This works because rails extends Fixnum to respond to things like #months, #years etc.
    (Date.strptime(beginning_of_embargo_range, "%m/%d/%Y") + number.send(increment)).strftime("%m/%d/%Y")
  end

  def embargo_date_is_correct_format
    # TODO: This isn't really working when a bad date is entered.
    # This doesn't end up erroring out and it errors up in embargo_date instead
    begin
      Date.strptime(embargo_date, "%m/%d/%Y")
    rescue ArgumentError
      errors.add(:embargo_date, 'must be a valid date')
    end
  end

  def under_embargo?
    !collection.blank? and collection.embargo_option == "varies"
  end

  def embargo_date_in_range
    if under_embargo? and embargo == "future"
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

  def update_access_blocks(ds,group)
    if group == "world"
      ds.send(:make_world_readable)
    else
      ds.send(:remove_world_read_access)
      ds.send(:add_read_group, group)
    end
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

