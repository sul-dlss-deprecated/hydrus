class Hydrus::GenericObject < Dor::Item

  include ActiveModel::Validations
  include Hydrus::ModelHelper
  include Hydrus::Validatable
  include Hydrus::Processable
  include Hydrus::Contentable
  include Hydrus::WorkflowDsExtension
  include Hydrus::Cant
  extend  Hydrus::Cant
  extend  Hydrus::Delegatable

  attr_accessor :files_were_changed

  validates :pid, :is_druid => true
  validate :check_contact_email_format, :if => :should_validate

  # We are using the validates_email_format_of gem to check email addresses.
  # Normally, you can use this tool with a simple validates() call:
  #
  #   validates :contact, :email_format => {:message => '...'}
  #
  # However, that resulted in an extraneous :contact key in the errors.messages
  # hash whenever a Collection had a validation error not involving the contact
  # email. This approach solved the problem.
  def check_contact_email_format
    problems = ValidatesEmailFormatOf::validate_email_format(contact)
    return if problems.nil?
    errors.add(:contact, "is not a valid email address")
  end

  has_metadata(
    :name => "rightsMetadata",
    :type => Hydrus::RightsMetadataDS,
    :label => 'Rights Metadata',
    :control_group => "M")

  has_metadata(
    :name => "descMetadata",
    :type => Hydrus::DescMetadataDS,
    :label => 'Descriptive Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "hydrusProperties",
    :type => Hydrus::HydrusPropertiesDS,
    :label => 'Hydrus Properties',
    :control_group => 'X')

  setup_delegations(
    # [:METHOD_NAME,              :uniq, :at... ]
    "descMetadata" => [
      [:title,                    true,  :main_title ],
      [:abstract,                 true   ],
      [:related_item_title,       false, :relatedItem, :titleInfo, :title],
      [:contact,                  true   ],
    ],
    "hydrusProperties" => [
      [:disapproval_reason,                 true   ],
      [:object_status,                      true   ],
      [:submitted_for_publish_time,         true   ],
      [:initial_submitted_for_publish_time, true   ],
      [:initial_publish_time,               true   ],
      [:submit_for_approval_time,           true   ],
      [:last_modify_time,                   true   ],
      [:item_type,                          true   ],
      [:object_version,                     true   ],
    ],
    "rightsMetadata" => [
      [:rmd_embargo_release_date, true,  :read_access, :machine, :embargo_release_date],
      [:terms_of_use,             true,  ],
    ],
  )

  def is_item?
    self.class == Hydrus::Item
  end

  def is_collection?
    self.class == Hydrus::Collection
  end

  def is_apo?
    false
  end

  # the pid without the druid: prefix
  def dru
    pid.gsub('druid:','')
  end

  # Returns true if all required fields are filled in.
  def required_fields_completed?
    # Validate, and return true if all is OK.
    return true if validate!
    # If the intersection of the errors keys and the required fields
    # is empty, the required fields are complete and the validation errors
    # are coming from other problems.
    return (errors.keys & self.class::REQUIRED_FIELDS).size == 0
  end

  # Notes:
  #   - We override save() so we can control whether editing events are logged.
  #   - This method is called via the normal operations of the web app, and
  #     during Hydrus remediations.
  #   - The :no_super is used to prevent the super() call during unit tests.
  def save(opts = {})
    # beautify_datastream(:descMetadata) unless opts[:no_beautify]
    unless opts[:is_remediation]
      self.last_modify_time = HyTime.now_datetime
      log_editing_events() unless opts[:no_edit_logging]
    end
    publish_metadata() if (is_collection? && is_published && is_open)
    super() unless opts[:no_super]
  end

  # Takes a datastream name, such as :descMetadata or 'rightsMetadata'.
  # Replaces that datastream's XML content with a beautified version of the XML.
  # NOTE: not being used currently, because strange problems occurred
  #       when this method was invoked in save().
  def beautify_datastream(dsid)
    ds         = datastreams[dsid.to_s]
    ds.content = beautified_xml(ds.content)
    ds.content_will_change!
  end

  # Takes some XML as a String.
  # Creates a Nokogiri document based on that XML, minus whitespace-only nodes.
  # Returns a new XML string, using Nokogiri's default indentation rules to
  # produce nice looking XML.
  # NOTE: not being used currently, because strange problems occurred
  #       when this method was invoked via save().
  def beautified_xml(orig_xml)
    nd = Nokogiri::XML(orig_xml, &:noblanks)
    return nd.to_xml
  end

  # Lazy initializers for instance variables.
  # We cannot set these value within a constructor, because
  # some Items and Collections are obtained in ways that won't call
  # our constructor code -- for example, Hydrus::Item.find().
  def current_user
    return (@current_user ||= '')
  end

  def current_user=(val)
    @current_user = val
  end

  # Returns true if the object is in the draft state.
  def is_draft
    return object_status == 'draft'
  end

  # Returns true if the object status is any flavor of published. This status
  # is Hydrus-centric and aligns with the submitted_for_publish_time -- the
  # moment the user clicks Open/Approve/Publish in the UI. By contrast,
  # publish_time focuses on the time the object achieves the published
  # milestone in common accessioning.
  def is_published
    return object_status[0..8] == 'published'
  end

  def apo
    @apo ||= (apo_pid ? get_fedora_item(apo_pid) : Hydrus::AdminPolicyObject.new)
  end

  def apo_pid
    @apo_pid ||= admin_policy_object_ids.first
  end

  def get_fedora_item(pid)
    return ActiveFedora::Base.find(pid, :cast => true)
  end

  # Since we need a custom setter, let's define the getter too
  # (rather than using delegation).
  def related_item_url
    return descMetadata.relatedItem.location.url
  end

  # Takes an argument, typically an OM-ready hash. For example:
  #   {'0' => 'url_foo', '1' => 'url_bar'}
  # Modifies the URL values so that they all begin with a protocol.
  # Then assigns the entire thing to relatedItem.location.url.
  def related_item_url=(h)
    if h.kind_of?(Hash)
      h.keys.each { |k| h[k] = with_protocol(h[k]) }
    else
      h = with_protocol(h)
    end
    descMetadata.relatedItem.location.url = h
  end

  # Takes a string that is supposed to be a URI.
  # Returns the same string if it begins with a known protocol.
  # Otherwise, returns the string as an http URI.
  def with_protocol(uri)
    return uri if uri.blank?
    return uri if uri =~ /\A (http|https|ftp|sftp):\/\/ /x
    return "http://" + uri
  end

  def discover_access
    return rightsMetadata.discover_access.first
  end

  def purl_url
   "#{Dor::Config.purl.base_url}#{dru}"
  end

  def related_items
    @related_items ||= descMetadata.find_by_terms(:relatedItem).map { |n|
      Hydrus::RelatedItem.new_from_node(n)
    }
  end

  # Takes an item_type: :dataset, etc. for items, or just :collection for collections.
  # Adds some Hydrus-specific information to the identityMetadata.
  def set_item_type(typ)
    self.hydrusProperties.item_type=typ.to_s
    if typ == :collection
      identityMetadata.add_value(:objectType, 'set')
      identityMetadata.content_will_change!
      descMetadata.ng_xml.search('//mods:mods/mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').each do |node|				
				node['collection']='yes'
      end
    else
      case typ
      when 'dataset'
        descMetadata.typeOfResource="software, multimedia"
        descMetadata.genre="dataset"
      when 'thesis'
        descMetadata.typeOfResource="text"
        descMetadata.insert_genre
        descMetadata.genre="thesis"
        #this is messy but I couldnt get OM to do what I needed it to
        descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first['authority'] = 'marcgt'
      when 'article'
        descMetadata.typeOfResource="text"
        descMetadata.genre="article"
        descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first['authority'] = 'marcgt'
      when 'class project'
        descMetadata.typeOfResource="text"
        descMetadata.genre="student project report"
      else
        descMetadata.typeOfResource=typ.to_s
      end
      descMetadata.content_will_change!
    end
  end
  
  # the possible types of items that can be created, hash of display value (keys) and values to store in object (value)
  def self.item_types
    {
      "data set"      => "dataset",
      "thesis"        => "thesis",
      "article"       => "article",
      "class project" => "class project",
      "computer game" => "computer game",
      "video" => "video",      
      "audio - music" => "audio - music",   
      "audio - spoken" => "audio - spoken",      
      "conference paper / presentation" => "conference paper / presentation",      
      "technical report" => "technical report",
      "other"         => "other"                        
    }
  end
  
  # Returns a data structure intended to be passed into
  # grouped_options_for_select(). This is an awkward approach (too
  # view-centric), leading to some minor data duplication in other
  # license-related methods, along with some overly complex lookup methods.
  def self.license_groups
    [
      ['None',  [
        ['No license', 'none'],
      ]],
      ['Creative Commons Licenses',  [
        ['CC BY Attribution'                                 , 'cc-by'],
        ['CC BY-SA Attribution Share Alike'                  , 'cc-by-sa'],
        ['CC BY-ND Attribution-NoDerivs'                     , 'cc-by-nd'],
        ['CC BY-NC Attribution-NonCommercial'                , 'cc-by-nc'],
        ['CC BY-NC-SA Attribution-NonCommercial-ShareAlike'  , 'cc-by-nc-sa'],
        ['CC BY-NC-ND Attribution-NonCommercial-NoDerivs'    , 'cc-by-nc-nd'],
      ]],
      ['Open Data Commons Licenses',  [
        ['PDDL Public Domain Dedication and License'         , 'pddl'],
        ['ODC-By Attribution License'                        , 'odc-by'],
        ['ODC-ODbl Open Database License'                    , 'odc-odbl'],
      ]],
    ]
  end

  # Should consolidate with info in license_groups().
  def self.license_commons
    return {
      'Creative Commons Licenses'  => "creativeCommons",
      'Open Data Commons Licenses' => "openDataCommons",
    }
  end

  # Should consolidate with info in license_groups().
  def self.license_group_urls
    return {
      "creativeCommons" => 'http://creativecommons.org/licenses/',
      "openDataCommons" => 'http://opendatacommons.org/licenses/',
    }
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Returns the corresponding text description of that license.
  def self.license_human(code)
    code = 'none' if code.blank?
    lic = license_groups.map(&:last).flatten(1).find { |txt, c| c == code }
    return lic ? lic.first : "Unknown license"
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Returns the corresponding license group code: eg, creativeCommons.
  def self.license_group_code(code)
    hgo = Hydrus::GenericObject
    hgo.license_groups.each do |grp, licenses|
      licenses.each do |txt, c|
        return hgo.license_commons[grp] if c == code
      end
    end
    return nil
  end

  # Returns the text label of the object's license.
  def license_text
    nds = rightsMetadata.use.human.nodeset
    nd  = nds.find { |nd| nd[:type] != 'useAndReproduction' }
    return nd ? nd.content : ''
  end

  # Returns the license group code (eg creativeCommons) corresponding
  # to the object's license.
  def license_group_code
    return rightsMetadata.use.machine.type.first
  end

  # Returns the object's license code: cc-by, pddl...
  # Returns license code of 'none' if there is no license, a
  # behavior that parallels the setter.
  #
  # Note: throughout the Hydrus app, creativeCommons license codes
  # have a cc- prefix, which disambiguates those code from similar
  # openDataCommons licenses; however, in the rightsMetadata XML
  # the creativeCommons codes lack the cc- prefix. That's why the
  # license getter and setter add and remove those prefixes.
  def license
    nd = rightsMetadata.use.machine.nodeset.first
    return 'none' unless nd
    prefix = nd[:type] == 'creativeCommons' ? 'cc-' : ''
    return prefix + nd.text
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Replaces the existing license, if any, with the license for that code.
  def license=(code)
    rightsMetadata.remove_license()
    return if code == 'none'
    hgo   = Hydrus::GenericObject
    gcode = hgo.license_group_code(code)
    txt   = hgo.license_human(code)
    code  = code.sub(/\Acc-/, '') if gcode == 'creativeCommons'
    rightsMetadata.insert_license(gcode, code, txt)
  end

  # Takes a symbol (:collection or :item).
  # Returns a hash of two hash, each having object_status as its
  # keys and human readable labels as values.
  def self.status_labels(typ, status = nil)
    h = {
      :collection => {
        'draft'             => "draft",
        'published_open'    => "published",
        'published_closed'  => "published",
      },
      :item       => {
        'draft'             => "draft",
        'awaiting_approval' => "waiting for approval",
        'returned'          => "item returned",
        'published'         => "published",
      },
    }
    return status ? h[typ] : h[typ]
  end

  # Takes an object_status value.
  # Returns its corresponding label.
  def self.status_label(typ, status)
    return status_labels(typ)[status]
  end

  # Returns a human readable label corresponding to the object's status.
  def status_label
    h1 = Hydrus::GenericObject.status_labels(:collection)
    h2 = Hydrus::GenericObject.status_labels(:item)
    return h1.merge(h2)[object_status]
  end

  def self.stanford_terms_of_use
    return '
      User agrees that, where applicable, content will not be used to identify
      or to otherwise infringe the privacy or confidentiality rights of
      individuals.  Content distributed via the Stanford Digital Repository may
      be subject to additional license and use restrictions applied by the
      depositor.
    '.squish
  end

  # Registers an object in Dor, and returns it.
  def self.register_dor_object(*args)
    params = self.dor_registration_params(*args)
    return Dor::RegistrationService.register_object(params)
  end

  # Returns a hash of info needed to register a Dor object.
  def self.dor_registration_params(user_string, obj_typ, apo_pid)
    proj = 'Hydrus'
    tm   = HyTime.now_datetime_full
    return {
      :object_type       => obj_typ,
      :admin_policy      => apo_pid,
      :source_id         => { proj => "#{obj_typ}-#{user_string}-#{tm}" },
      :label             => proj,
      :tags              => ["Project : #{proj}"],
      :initiate_workflow => [Dor::Config.hydrus.app_workflow],
    }
  end

  def recipients_for_object_returned_email
    is_collection? ? owner : item_depositor_id
  end

  def send_object_returned_email_notification(opts={})
    return if recipients_for_object_returned_email.blank?
    email=HydrusMailer.object_returned(:returned_by => @current_user, :object => self, :item_url=>opts[:item_url])
    email.deliver unless email.blank?
  end

  # After collections are published, further edits to the object are allowed.
  # This occurs without requiring the open_new_version() process used by Items.
  #
  # Here's an overview:
  #   - User open Collection for the first time.
  #   - Hydrus kicks off the assemblyWF/accessionWF pipeline.
  #   - Later, user edits Collection and clicks Save.
  #   - The save() method in Hydrus invokes publish_metadata().
  #   - Here we simply call super(), which delegates to the dor-services gem,
  #     provided that we are running in an environment intended to use the
  #     entire the assembly/accessioning/publishing pipeline.
  #   - Later, a nightly cron job (not built yet) will patrol Fedora, looking
  #     for modified Collections and APOs. If it finds any, it will open a new
  #     version and run the object through the pipeline.
  def publish_metadata
    return unless should_start_assembly_wf
    cannot_do(:publish_metadata) unless is_assemblable()
    super()
  end

  # Returns string representation of the class, minus the Hydrus:: prefix.
  # For example: Hydrus::Collection -> 'Collection'.
  def hydrus_class_to_s
    return self.class.to_s.sub(/\AHydrus::/, '')
  end

  def get_hydrus_events
    es = []
    events.find_events_by_type('hydrus') do |who, whe, msg|
      es.push(Hydrus::Event.new(who, whe, msg))
    end
    return es
  end

  # If the current object differs from the object's old self in federa,
  # editing events are logged.
  def log_editing_events
    cfs = changed_fields()
    return if cfs.length == 0
    events.add_event('hydrus', @current_user, editing_event_message(cfs))
  end

  # Compares the current object to its old self in fedora.
  # Returns the list of fields for which differences are found.
  # The comparisons are driven by the hash-of-arrays returned by
  # tracked_fields() from the Item or Collection class.
  def changed_fields
    old = old_self()
    cfs = []
    tracked_fields.each do |k,fs|
      next if fs.all? { |f| equal_when_stripped? old.send(f), self.send(f) }
      cfs.push(k)
    end
    return cfs
  end

  # Returns the version of the object as it exists in fedora.
  def old_self
    @cached_old_self ||= self.class.find(pid)
  end

  # Takes a list of fields that were changed by the user and
  # returns a string used in event logging. For example:
  #   "Item modified: title, abstract, license"
  def editing_event_message(fields)
    fs = fields.map { |e| e.to_s }.join(', ')
    return "#{hydrus_class_to_s()} modified: #{fs}"
  end

  def purl_page_ready?
    return RestClient.get(purl_url) { |resp, req, res| resp }.code == 200
  end

end
