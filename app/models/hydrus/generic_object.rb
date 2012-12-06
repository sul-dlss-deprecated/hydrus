class Hydrus::GenericObject < Dor::Item

  include Hydrus::ModelHelper
  include Hydrus::Validatable
  include Hydrus::WorkflowDsExtension
  extend  Hydrus::Delegatable
  include ActiveModel::Validations

  attr_accessor :files_were_changed

  validates :pid, :is_druid => true
  validates :contact, :email_format => {:message => 'is not a valid email address'}, :if => :should_validate

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
    :control_group => 'M')

  setup_delegations(
    # [:METHOD_NAME,              :uniq, :at... ]
    "descMetadata" => [
      [:title,                    true,  :main_title ],
      [:abstract,                 true   ],
      [:related_item_title,       false, :relatedItem, :titleInfo, :title],
      [:contact,                  true   ],
    ],
    "hydrusProperties" => [
      [:disapproval_reason,       true   ],
      [:object_status,            true   ],
      [:publish_time,             true   ],
      [:submit_for_approval_time, true   ],
      [:last_modify_time,         true   ],
      [:item_type,                true   ],
    ],
    "rightsMetadata" => [
      [:rmd_embargo_release_date, true,  :read_access, :machine, :embargo_release_date],
    ],
  )

  # delete the file upload directory and then call the super method
  def delete
    parent_object_directory=File.join(self.base_file_directory,'..')
    FileUtils.rm_rf(parent_object_directory) if File.directory?(parent_object_directory)
    super
  end

  def is_item?
    self.class == Hydrus::Item
  end

  def is_collection?
    self.class == Hydrus::Collection
  end

  # the pid without the druid: prefix
  def dru
    pid.gsub('druid:','')
  end

  # Returns true if all required fields are filled in.
  def required_fields_completed?
    # Validate, and return true if all is OK.
    return true if validate!
    # Get keys in the errors hash that have non-blank values.
    # The presence of a key does not indicate an error; you have to check the value.
    es = errors.reject { |k,v| v.blank? }.map { |k,v| k }.uniq
    # If the intersection of those keys and the required fields
    # is empty, the required fields are complete and the validation errors
    # are coming from other problems.
    return (es & self.class::REQUIRED_FIELDS).size == 0
  end

  # We override save() so we can control whether editing events are logged.
  # Notes on options:
  #   :no_super     To prevent the super() call during unit tests
  #   :no_beautify  To prevent a strange error that we haven't doped out yet.
  def save(opts = {})
    # beautify_datastream(:descMetadata) unless opts[:no_beautify]
    self.last_modify_time = HyTime.now_datetime
    log_editing_events() unless opts[:no_edit_logging]
    super() unless opts[:no_super]
  end

  # Takes a datastream name, such as :descMetadata or 'rightsMetadata'.
  # Replaces that datastream's XML content with a beautified version of the XML.
  def beautify_datastream(dsid)
    ds         = datastreams[dsid.to_s]
    ds.content = beautified_xml(ds.content)
    ds.content_will_change!
  end

  # Takes some XML as a String.
  # Creates a Nokogiri document based on that XML, minus whitespace-only nodes.
  # Returns a new XML string, using Nokogiri's default indentation rules to
  # produce nice looking XML.
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

  # Returns true if the object status is any flavor of published.
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
  def augment_identity_metadata(typ)
    identityMetadata.add_value(:objectType, 'set') if typ == :collection
    identityMetadata.add_value(:tag, "Hydrus : #{typ}")
    identityMetadata.content_will_change!
  end

  def self.licenses
    {
      'Creative Commons Licenses' =>  [
        ['CC BY Attribution'                                 , 'cc-by'],
        ['CC BY-SA Attribution Share Alike'                  , 'cc-by-sa'],
        ['CC BY-ND Attribution-NoDerivs'                     , 'cc-by-nd'],
        ['CC BY-NC Attribution-NonCommercial'                , 'cc-by-nc'],
        ['CC BY-NC-SA Attribution-NonCommercial-ShareAlike'  , 'cc-by-nc-sa'],
        ['CC BY-NC-ND Attribution-NonCommercial-NoDerivs'    , 'cc-by-nc-nd'],
      ],
      'Open Data Commons Licenses'  =>  [
        ['PDDL Public Domain Dedication and License'         , 'pddl'],
        ['ODC-By Attribution License'                        , 'odc-by'],
        ['ODC-ODbl Open Database License'                    , 'odc-odbl'],
      ]
    }
  end

  def self.license_type(code)
    return "" if code.blank?
    if code[0..1].downcase == 'cc'
      "creativeCommons"
    elsif code.downcase == 'pddl' || code[0..2].downcase == 'odc'
      "openDataCommons"
    else
      ""
    end
  end

  def self.license_human(code)
    licenses.each do |type, license|
      license.each do |lic|
        return lic.first if code == lic.last
      end
    end
    return "No license. All rights reserved by content creator."
  end

  def self.license_commons
    return {
      'Creative Commons Licenses'  => "creativeCommons",
      'Open Data Commons Licenses' => "openDataCommons",
    }
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

  # Registers an object in Dor, and returns it.
  def self.register_dor_object(*args)
    params = self.dor_registration_params(*args)
    return Dor::RegistrationService.register_object(params)
  end

  # Returns a hash of info needed to register a Dor object.
  def self.dor_registration_params(user_string, obj_typ, apo_pid)
    proj = 'Hydrus'
    wfs  = obj_typ == 'adminPolicy' ? [] : [Dor::Config.hydrus.app_workflow]
    tm   = HyTime.now_datetime_full
    return {
      :object_type       => obj_typ,
      :admin_policy      => apo_pid,
      :source_id         => { proj => "#{obj_typ}-#{user_string}-#{tm}" },
      :label             => proj,
      :tags              => ["Project : #{proj}"],
      :initiate_workflow => wfs,
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
    if DruidTools::Druid.valid?(self.pid)
      # write xml to a file
      FileUtils.mkdir_p(metadata_directory) unless File.directory? metadata_directory
      f = File.join(metadata_directory, 'contentMetadata.xml')
      File.open(f, 'w') { |fh| fh.puts xml }
    end
    datastreams['contentMetadata'].content = xml
  end

  def create_content_metadata
    if is_item?
      objects = files.collect { |file| Assembly::ObjectFile.new(file.current_path, :label=>file.label)}
    else
      objects = []
    end
    return Assembly::ContentMetadata.create_content_metadata(
      :druid            => pid,
      :objects          => objects,
      :add_file_attributes => true,
      :style            => Hydrus::Application.config.cm_style,
      :file_attributes  => Hydrus::Application.config.cm_file_attributes,
      :include_root_xml => false)
  end

  # If the app is configured to start the common assembly workflow, calls will
  # be made to the workflow service to begin that process. In addition,
  # contentMetadata is generated for Items.
  def start_common_assembly
    return unless should_start_common_assembly
    cannot_do(:start_common_assembly) unless is_assemblable()
    update_content_metadata
    complete_workflow_step('start-assembly')
    initiate_apo_workflow('assemblyWF')
  end

  # Returns value of Dor::Config.hydrus.start_common_assembly.
  # Wrapped in method to simplify testing stubs.
  def should_start_common_assembly
    return Dor::Config.hydrus.start_common_assembly
  end

  # Returns string representation of the class, minus the Hydrus:: prefix.
  # For example: Hydrus::Collection -> 'Collection'.
  def hydrus_class_to_s
    return self.class.to_s.sub(/\AHydrus::/, '')
  end

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def complete_workflow_step(step)
    return if workflows.workflow_step_is_done(step)
    awf = Dor::Config.hydrus.app_workflow
    Dor::WorkflowService.update_workflow_status('dor', pid, awf, step, 'completed')
    workflows_content_is_stale
  end

  # This method resets two instance variables of the workflow datastream.  By
  # resorting to this encapsulation-violating hack, we ensure that our current
  # Hydrus object will not rely on its cached copy of the workflow XML.
  # Instead it will call to the workflow service to get the latest XML,
  # particularly during the save() process, which is when our object will be
  # resolarized.
  def workflows_content_is_stale
    %w(@content @ng_xml).each { |v| workflows.instance_variable_set(v, nil) }
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
    return self.class.find(pid)
  end

  # Takes a list of fields that were changed by the user and
  # returns a string used in event logging. For example:
  #   "Item modified: title, abstract, license"
  def editing_event_message(fields)
    fs = fields.map { |e| e.to_s }.join(', ')
    return "#{hydrus_class_to_s()} modified: #{fs}"
  end

  def purl_page_ready?
    begin
      Dor::WorkflowService.get_workflow_status('dor', pid, 'accessionWF', 'publish') == 'completed'
    rescue
      false
    end
  end

  # A utility method that raises an exception indicating that the
  # object cannot perform an action like open(), close(), approve(), etc.
  def cannot_do(action)
    msg = "object_type=#{hydrus_class_to_s}, action=#{action}, pid=#{pid}"
    raise "Cannot perform action: #{msg}."
  end

  def license *args
    rightsMetadata.use.machine(*args).first
  end

  def license= val
    rightsMetadata.remove_nodes(:use)
    Hydrus::Collection.licenses.each do |type,licenses|
      licenses.each do |license|
        if license.last == val
          # TODO I would like to do this type_attribute part better.
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

  # A temporary hack until dor-services fixes a bug in describable.rb.
  def n_hydrus_related_items
    nodes = descMetadata.find_by_terms(:relatedItem).select { |n| n['type'].nil? }
    return nodes.size
  end

end
