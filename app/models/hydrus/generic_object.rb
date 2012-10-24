class Hydrus::GenericObject < Dor::Item

  include Hydrus::ModelHelper
  include Hydrus::Publishable
  include Hydrus::WorkflowDsExtension
  extend  Hydrus::Delegatable
  include ActiveModel::Validations

  attr_accessor :files_were_changed

  REQUIRED_FIELDS=[:title,:abstract,:contact]
  REQUIRED_FIELDS.each {|field| validates field, :not_empty => true, :if => :should_validate}
  
  validates :pid, :is_druid => true

  setup_delegations(
    # [:METHOD_NAME,         :uniq, :at... ]
    "descMetadata" => [
      [:title,               true,  :main_title ],
      [:abstract,            true   ],
      [:related_item_title,  false, :relatedItem, :titleInfo, :title],
      [:related_item_url,    false, :relatedItem, :location, :url],
      [:contact,             true   ],
    ],
    "hydrusProperties" => [
      [:disapproval_reason,  true   ],
    ],
  )

  def is_collection?
    self.class == Hydrus::Collection
  end

  # if we are a collection, return the value from the datastream, if not, return this item's collections value
  def requires_human_approval
    is_collection? ? super : collection.requires_human_approval
  end
    
  #################################
  # methods used to build sidebar #
  def required_fields_completed?  # returns true if all required fields are filled in, otherwise returns false
    validate! ? true : (errors.keys & REQUIRED_FIELDS).size == 0  # if validations are true, returns true, if not runs an intersection of invalid fields with required fields and indicates if this is blank
  end
  #################################  
  
  # We override save() so we can control whether editing events are logged.
  def save(opts = {})
    log_editing_events() unless opts[:no_edit_logging]
    super()
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

  
  def is_approvable
    is_published ? false : (to_bool(requires_human_approval) ? validate! && !is_submitted_for_approval : false)
  end
  
  # Returns true only if the Item is unpublished.
  def is_destroyable
    return not(is_published)
  end

  def is_published
    unless defined?(@is_published)
      @is_published = to_bool(requires_human_approval) ?  is_approved : is_submitted
    end
    return @is_published
  end

  def is_submitted
    workflow_step_is_done('submit')
  end
  
  def is_submitted_for_approval
    return (is_submitted and !workflow_step_is_done('approve'))
  end
  
  def is_approved
    return (is_submitted and workflow_step_is_done('approve'))
  end

  # The controller will call these methods, which we simply forward to
  # the Collection or Item class.
  def publish=(val) publish(val) end
  def approve=(val) approve(val) end
  def resubmit=(val) resubmit(val) end
    
  def object_type
    # TODO: this is not what we want.
    return identityMetadata.objectType.first
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

  def discover_access
    return rightsMetadata.discover_access.first
  end

  def url
   "http://purl.stanford.edu/#{pid}"
  end

  def related_items
    @related_items ||= descMetadata.find_by_terms(:relatedItem).map { |n|
      Hydrus::RelatedItem.new_from_node(n)
    }
  end

  # Adds some Hydrus-specific information to the identityMetadata.
  def augment_identity_metadata(object_type)
    identityMetadata.add_value(:objectType, 'set') if object_type == :collection
    identityMetadata.add_value(:tag, "Hydrus : #{object_type}")
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
  end

  def self.license_commons
    return {
      'Creative Commons Licenses'  => "creativeCommons",
      'Open Data Commons Licenses' => "openDataCommons",
    }
  end

  # Registers an object in Dor, and returns it.
  def self.register_dor_object(*args)
    params = self.dor_registration_params(*args)
    return Dor::RegistrationService.register_object(params)
  end

  # Returns a hash of info needed to register a Dor object.
  def self.dor_registration_params(user_string, object_type, apo_pid)
    proj = 'Hydrus'
    wfs  = object_type == 'adminPolicy' ? [] : [Dor::Config.hydrus.app_workflow]
    tm   = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L %z')  # With milliseconds.
    return {
      :object_type       => object_type,
      :admin_policy      => apo_pid,
      :source_id         => { proj => "#{object_type}-#{user_string}-#{tm}" },
      :label             => proj,
      :tags              => ["Project : #{proj}"],
      :initiate_workflow => wfs,
    }
  end

  # Optionally takes a hash like this: 
  #   { 'value'  => 'yes|no', 'reason' => 'blah blah' }
  # Implements approve/disapprove accordingly.
  def approve(h = nil)
    if h.nil? or to_bool(h['value'])
      do_approve()
    else
      do_disapprove(h['reason'])
    end
  end

  # Approves an object by marking the 'approve' step in the Hydrus workflow as
  # completed. If the app is configured to start the common assembly workflow,
  # additional calls will be made to the workflow service to begin that
  # process as well. In that case, we also generate content metadata.
  def do_approve
    is_item = is_hydrus_item()
    complete_workflow_step('approve')
    events.add_event('hydrus', @current_user, "#{hydrus_class_to_s()} approved") if to_bool(requires_human_approval) && !is_collection?
    hydrusProperties.remove_nodes(:disapproval_reason)
    if should_start_common_assembly
      update_content_metadata if is_item
      complete_workflow_step('start-assembly')
      initiate_apo_workflow('assemblyWF')
    end
  end

  # Disapproves an object by setting the reason is the hydrusProperties datastream.
  def do_disapprove(reason)
    events.add_event('hydrus', @current_user, "Item disapproved: #{reason}")
    self.disapproval_reason = reason
    recipients = (is_collection? ? '' : item_depositor_id)
    unless recipients.blank?
      recipients=[recipients] unless recipients.class == Array
      email = HydrusMailer.object_returned(:to => recipients.join(", "), :returned_by => @current_user, :object => self)
      email.deliver unless email.to.blank? # this will catch when we're trying to send an email from a fixture.
    end    
  end
  
  # Returns true if there is a non-blank disapproval_reason.
  def is_disapproved
    is_published ? false : (to_bool(requires_human_approval) ? !disapproval_reason.blank? : false)
  end

  # Returns value of Dor::Config.hydrus.start_common_assembly.
  # Wrapped in method to simplify testing stubs.
  def should_start_common_assembly
    return Dor::Config.hydrus.start_common_assembly
  end

  # Returns true if object is a Hydrus::Item.
  def is_hydrus_item
    return self.class == Hydrus::Item
  end

  # Returns string representation of the class, minus the Hydrus:: prefix.
  # For example: Hydrus::Collection -> 'Collection'.
  def hydrus_class_to_s
    return self.class.to_s.sub(/\AHydrus::/, '')
  end

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def complete_workflow_step(step)
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

  def submit_time
    s = 'submit'
    return nil unless workflow_step_is_done(s)
    return get_workflow_step(s)['datetime']
  end

  def publish_lifecycle_time
    q = "//process[@lifecycle='published']"
    node = workflows.find_by_xpath(q).first
    return nil unless (node and node['status'] == 'completed')
    return node['datetime']
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

  ####
  # Delegate some functionality to workflow DS.
  # Could not get this to work using delegate().
  ####

  def get_workflow_node
    return workflows.get_workflow_node
  end

  def get_workflow_step(step)
    return workflows.get_workflow_step(step)
  end

  def get_workflow_status(step)
    return workflows.get_workflow_status(step)
  end

  def workflow_step_is_done(step)
    return workflows.workflow_step_is_done(step)
  end

end
