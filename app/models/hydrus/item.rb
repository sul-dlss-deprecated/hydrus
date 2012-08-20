class Hydrus::Item < Hydrus::GenericObject

  include Hydrus::EmbargoMetadataDsExtension
  include Hydrus::Responsible
  
  after_validation :strip_whitespace
      
  attr_accessor :embargo
  
  validate :collection_is_open, :on => :create
  validates :actors, :at_least_one=>true, :if => :should_validate
  validates :files, :at_least_one=>true, :if => :should_validate
  validate  :must_accept_terms_of_deposit, :if => :should_validate
  # validate  :embargo_date_is_correct_format # TODO

  delegate :accepted_terms_of_deposit, :to => "hydrusProperties", :unique => true

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
    # Add roleMetadata with current user as item-depositor.
    item.roleMetadata.add_person_with_role(user, 'item-depositor')
    # Add event.
    item.events.add_event('hydrus', user, 'Item created')
    # Save and return.
    item.save
    return item
  end

  # Publish the Item.
  def publish(value)
    # At the moment of publication, we refresh various titles.
    identityMetadata.objectLabel = title
    # Advance workflow to record that the object has been published.
    s = 'submit'
    unless workflow_step_is_done(s)
      complete_workflow_step(s)
      events.add_event('hydrus', @current_user, 'Item published')
      approve() unless requires_human_approval
    end
  end
  
  # Returns true if the Item's Collection requires items to be
  # reviewed/approved before ultimate release.
  def requires_human_approval
    to_bool(collection.requires_human_approval)
  end

  # Returns the Item's Collection.
  def collection
    cs = super       # Get all collections.
    return cs.first  # In Hydrus, we assume there is just one (for now).
  end

  def update_content_metadata
    xml=create_content_metadata
    self.datastreams['contentMetadata'].content=xml  # generate new content metadata and replace datastream
    self.save
  end
  
  def create_content_metadata
    objects=self.files.collect{|file| Assembly::ObjectFile.new(file.current_path,:label=>file.label)}
    objects.empty? ? '' : Assembly::ContentMetadata.create_content_metadata(:druid=>pid,:objects=>objects,:style=>:file,:include_root_xml=>false)  
  end
  
  # Returns true only if the Item is unpublished.
  def is_destroyable
    return not(is_published)
  end

  # Returns true only if the Item has an open Collection.
  def collection_is_open
    c = collection
    return true if c && c.is_open
    errors.add(:collection, "must be open to have new items added")
    return false
  end

  # the user must have accepted the terms of deposit to publish
  def must_accept_terms_of_deposit
    if to_bool(accepted_terms_of_deposit) != true
      errors.add(:terms_of_deposit, "must be accepted")
    end
  end
  
  def license *args
    unless (rightsMetadata.use.machine *args).first.blank?
      (rightsMetadata.use.machine *args).first
    else
      # Use the collection's license as a default in the absense of an item level license.
      collection.license
    end
  end
  
  def license= *args
    rightsMetadata.remove_nodes(:use)
    Hydrus::Collection.licenses.each do |type,licenses|
      licenses.each do |license| 
        if license.last == args.first
          # I would like to do this type_attribute part better.
          # Maybe infer the insert method and call send on rightsMetadata.
          type_attribute = Hydrus::Collection.license_commons[type]
          if type_attribute == "creativeCommons"
            rightsMetadata.insert_creative_commons
          elsif type_attribute == "openDataCommons"
            rightsMetadata.insert_open_data_commons
          end
          rightsMetadata.use.machine = *args
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
        groups << embargoMetadata.release_access_node.at_xpath('//access[@type="read"]/machine/group').text
      end
    else
      (rightsMetadata.read_access.machine.group).collect{|g| groups << g}
      (rightsMetadata.read_access.machine.world).collect{|g| groups << "world" if g.blank?}      
    end
    groups
  end
  
  def visibility= *args
    embargoMetadata.release_access_node = Nokogiri::XML(generic_release_access_xml) unless embargoMetadata.ng_xml.at_xpath("//access")
    if embargo == "immediate"
      embargoMetadata.release_access_node = Nokogiri::XML("<releaseAccess/>")
      rightsMetadata.remove_embargo_date
      embargoMetadata.remove_embargo_date
      update_access_blocks(rightsMetadata, args.first)
    elsif embargo == "future"
      rightsMetadata.remove_world_read_access
      rightsMetadata.remove_all_group_read_nodes
      update_access_blocks(embargoMetadata, args.first)
      embargoMetadata.release_date = Date.strptime(embargo_date, "%m/%d/%Y")
    end    
  end
    
  def embargo_date *args
    date = (rightsMetadata.read_access.machine.embargo_release_date *args).first
    Date.parse(date).strftime("%m/%d/%Y") unless date.blank?
  end
  
  def embargo_date= *args
    date = args.first.blank? ? "" : Date.strptime(args.first, "%m/%d/%Y").to_s
    (rightsMetadata.read_access.machine.embargo_release_date= date) unless date.blank?
  end
    
  def beginning_of_embargo_range
    submit_time ? Date.parse(submit_time).strftime("%m/%d/%Y") : Date.today.strftime("%m/%d/%Y")
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
    # TODO: This isn't really working when a bad date is entered. This doesn't end up erroring out and it errors up in embargo_date instead
    if ((Date.strptime(embargo_date, "%m/%d/%Y") rescue ArgumentError) == ArgumentError)
      errors.add(:embargo_date, 'must be a valid date')
    end
  end
  
  def files
    Hydrus::ObjectFile.find_all_by_pid(pid,:order=>'weight')  # coming from the database
  end
  
  delegate :preferred_citation, :to => "descMetadata", :unique => true
  delegate :related_citation, :to => "descMetadata"
  delegate :person, :to => "descMetadata", :at => [:name, :namePart]
  delegate :person_role, :to => "descMetadata", :at => [:name, :role, :roleTerm]

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

  delegate(:item_depositor_id, :to => "roleMetadata",
           :at => [:item_depositor, :person, :identifier], :unique => true)
  delegate(:item_depositor_name, :to => "roleMetadata",
           :at => [:item_depositor, :person, :name], :unique => true)

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
    kws = parse_delimited(val)
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
  
  def self.roles
    [ "Author",
      "Creator",
      "Collector",
      "Contributing Author",
      "Distributor",
      "Principal Investigator",
      "Publisher",
      "Sponsor" ]
  end
  
  def self.discovery_roles
    {"everyone" => "world", "Stanford only" => "stanford"}
  end

end
