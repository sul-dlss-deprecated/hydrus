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

  # Registers an object in Dor, and returns it.
  def self.register_dor_object(*args)
    params = self.dor_registration_params(*args)
    return Dor::RegistrationService.register_object(params)
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

  private

  # Returns a hash of info needed to register a Dor object.
  def self.dor_registration_params(user_string, object_type, apo_pid)
    proj = 'Hydrus'
    wfs  = object_type == 'adminPolicy' ? [] : [:hydrusAssemblyWF]
    return {
      :object_type       => object_type,
      :admin_policy      => apo_pid,
      :source_id         => { proj => "#{object_type}-#{user_string}-#{Time.now}" },
      :label             => proj,
      :tags              => ["Project : #{proj}"],
      :initiate_workflow => wfs,
    }
  end

end
