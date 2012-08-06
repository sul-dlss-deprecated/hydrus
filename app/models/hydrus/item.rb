class Hydrus::Item < Hydrus::GenericObject
  include Hydrus::EmbargoMetadataDsExtension
  include Hydrus::Responsible
  
  after_validation :strip_whitespace
      
  attr_accessor :terms_of_deposit, :embargo
  
  validates :actors, :at_least_one=>true, :if => :clicked_publish?
  validates :files, :at_least_one=>true, :if => :clicked_publish?
  #validate  :embargo_date_is_correct_format # TODO
  validates :terms_of_deposit, :presence => true, :if => :clicked_publish?
  validate  :collection_must_be_open, :on => :create

  # check to see if object is "publishable" (basically valid, but setting publish to true to run validations properly)
  def publishable?
    case publish
      when true
         self.valid?
      else 
        # we need to set publish to true to run validations
        self.publish=true
        result=self.valid?  
        self.publish=false
        return result
      end
  end
  
  # def publish=(value)
  #   # At the moment of publication, we refresh various titles.
  #   identityMetadata.objectLabel = title
  # end
  
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
    # Save and return.
    item.save
    return item
  end
  
  # at least one of the associated collections must be open (published) to create a new item
  def collection_must_be_open
    if !collection.collect {|c| c.publish}.include?(true)
      errors.add(:collection, "must be open to have new items added")
    end
  end
  
  def license *args
    unless (rightsMetadata.use.machine *args).first.blank?
      (rightsMetadata.use.machine *args).first
    else
      # Use the collection's license as a default in the absense of an item level license.
      collection[0].license
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
    # if the embargoMD has future world read access
    if embargoMetadata.release_access_node.at_xpath('//access[@type="read"]/machine/world')
      groups << "world" 
    else
      (rightsMetadata.read_access.machine.group *args).collect{|g| groups << g}
      (rightsMetadata.read_access.machine.world *args).collect{|g| groups << "world" if g.blank?}
    end
    groups
  end
  
  def visibility= *args
    if args.first == "world"
      if embargo == "immediate"
        # make the current rightsMD world
        rightsMetadata.remove_group_node("read", "stanford")
        rightsMetadata.read_access.machine.world = ""
        # remove embargo metadata from the rights and embargo datastreams.
        rightsMetadata.read_access.machine.embargo_release_date = ""
        embargoMetadata.release_date = Date.today
        embargoMetadata.release_access_node = Nokogiri::XML("<releaseAccess/>")
      elsif embargo == "future"
        # Add stanford to current groups in read access.
        rightsMetadata.read_access.machine.group = rightsMetadata.read_access.machine.group << "stanford" # I'm not sure how this will work with groups that have existing attributes.
        # add the world XML to embargoMD then set the release date
        embargoMetadata.release_access_node = Nokogiri::XML(world_release_access_node_xml)
        embargoMetadata.release_date = Date.strptime(embargo_date, "%m/%d/%Y")
      end
    elsif args.first == "stanford"
      rightsMetadata.remove_world_node("read")
      rightsMetadata.read_access.machine.group = rightsMetadata.read_access.machine.group << args.first # I'm not sure how this will work with groups that have existing attributes.
      if embargo == "immediate"
        rightsMetadata.read_access.machine.embargo_release_date = ""
        embargoMetadata.release_date = Date.today
        embargoMetadata.release_access_node = Nokogiri::XML("<releaseAccess/>")
      elsif embargo == "future"
        embargoMetadata.release_access_node = Nokogiri::XML(stanford_release_access_node_xml)
        embargoMetadata.release_date = Date.strptime(embargo_date, "%m/%d/%Y")
      end
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
    length = collection.first.apo.embargo
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
    
  def submit_time
    query = '//workflow[@id="hydrusAssemblyWF"]/process[@name="submit" and @status="completed"]'
    time=workflows.ng_xml.at_xpath(query)
    return (time ? time['datetime'] : nil)
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

  def keywords=(*args)
    descMetadata.remove_nodes(:subject)
    args.first.values.each { |kw| descMetadata.insert_topic(kw)  }
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
