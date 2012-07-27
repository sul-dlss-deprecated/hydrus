class Hydrus::Item < Hydrus::GenericObject
  
  after_validation :strip_whitespace
      
  attr_accessor :terms_of_deposit
  
  validates :actors, :at_least_one=>true, :if => :clicked_publish?
  validates :files, :at_least_one=>true, :if => :clicked_publish?
  validates :terms_of_deposit, :presence => true, :if => :clicked_publish?
  validate :collection_must_be_open, :on => :create
  
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
    @actors ||= descMetadata.find_by_terms(:name).collect {|name_node| Hydrus::Actor.new(:name=>name_node.at_css('namePart').content,:role=>name_node.at_css('role roleTerm').content)}
  end
    
  def submit_time
    query = '//workflow[@id="sdrDepositWF"]/process[@name="submit"]'
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
    ["everyone", "Stanford only"]
  end

end
