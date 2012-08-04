class Hydrus::GenericObject < Dor::Item
    
  attr_accessor :publish
  
  include Hydrus::ModelHelper
  include ActiveModel::Validations
  validates :title, :abstract, :contact, :not_empty => true, :if => :clicked_publish?
  
  validates :pid, :is_druid=>true
  
  attr_accessor :apo_pid

  has_metadata(
    :name => "descMetadata",
    :type => Hydrus::DescMetadataDS,
    :label => 'Descriptive Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "roleMetadata",
    :type => Hydrus::RoleMetadataDS,
    :label => 'Role Metadata',
    :control_group => 'M')

  def object_type
    identityMetadata.objectType.first
  end
    
  def clicked_publish?
    to_bool(publish)
  end
  
  delegate :abstract, :to => "descMetadata", :unique => true
  delegate :title, :to => "descMetadata", :unique => true
  delegate :related_item_title, :to => "descMetadata", :at => [:relatedItem, :titleInfo, :title]
  delegate :related_item_url, :to => "descMetadata", :at => [:relatedItem, :location, :url]
  delegate :contact, :to => "descMetadata", :unique => true
    
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
    return {
      :object_type       => object_type,
      :admin_policy      => apo_pid,
      :source_id         => { proj => "#{object_type}-#{user_string}-#{Time.now}" },
      :label             => proj,
      :tags              => ["Project : #{proj}"],
      :initiate_workflow => wfs,
    }
  end

  # Approves an object by marking the 'approve' step in the Hydrus workflow as
  # completed. If the app is configured to start the common assembly workflow,
  # additional calls will be made to the workflow service to begin that
  # process as well.
  def approve
    complete_workflow_step('approve')
    return unless Dor::Config.hydrus.start_common_assembly
    complete_workflow_step('start-assembly')
    initiate_apo_workflow('assemblyWF')
  end

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def complete_workflow_step(step)
    hawf = Dor::Config.hydrus.app_workflow
    Dor::WorkflowService.update_workflow_status('dor', pid, hawf, step, 'completed')
  end

  # Returns the hydrusAssemblyWF node from the object's workflows.
  def get_workflow_node
    wf = Dor::Config.hydrus.app_workflow
    q = "//workflow[@id='#{wf}']"
    return workflows.find_by_xpath(q).first
  end

  # Takes the name of a hydrusAssemblyWF step.
  # Returns the corresponding process node.
  def get_workflow_step(step)
    return get_workflow_node.at_xpath("//process[@name='#{step}']")
  end

  # Takes the name of a hydrusAssemblyWF step.
  # Returns the staus of the corresponding process node.
  def get_workflow_status(step)
    node = get_workflow_step(step)
    return node ? node['status'] : nil
  end

end
