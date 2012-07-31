class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject

  include Hydrus::ModelHelper

  # TODO: temporary fix until dor-services gem includes it in its APOs.
  include Dor::Processable
  
  validate :check_embargo_options, :if => :open_for_deposit?
  validate :check_license_options, :if => :open_for_deposit?
  validates :embargo_option, :presence => true, :if => :open_for_deposit?
  validates :license_option, :presence => true, :if => :open_for_deposit?

  def self.create(user)
    # Create the object, with the correct model.
    dconf = Dor::Config
    args = [user, 'adminPolicy', dconf.ur_apo_druid]
    apo  = Hydrus::GenericObject.register_dor_object(*args)
    apo  = apo.adapt_to(Hydrus::AdminPolicyObject)
    apo.remove_relationship :has_model, 'info:fedora/afmodel:Dor_AdminPolicyObject'
    apo.assert_content_model
    # Add the default workflows.
    dconf.hydrus.workflow_steps.keys.each do |wf_name|
      apo.administrativeMetadata.insert_workflow(wf_name)
    end
    # Add minimal descMetadata with a title.
    apo.title = dconf.hydrus.initial_apo_title
    # Add roleMetadata with current user as collection-manager.
    apo.roleMetadata.add_person_with_role(user, 'collection-manager')
    # Save and return.
    apo.save
    return apo
  end

  def check_embargo_options
    if embargo_option != 'none' && embargo.blank?
      errors.add(:embargo, "must have a time period specified")
    end
  end

  def check_license_options
    if license_option != 'none' && license.blank?
      errors.add(:license, "must be specified")
    end
  end

  def open_for_deposit?
   deposit_status == "open"
  end  
  
  has_metadata(
    :name => "descMetadata",
    :type => Hydrus::DescMetadataDS,
    :label => 'Descriptive Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "administrativeMetadata",
    :type => Hydrus::AdministrativeMetadataDS,
    :label => 'Administrative Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "roleMetadata",
    :type => Hydrus::RoleMetadataDS,
    :label => 'Role Metadata',
    :control_group => 'M')

  # descMetadata
  delegate :title, :to => "descMetadata", :unique => true

  # administrativeMetadata
  delegate(:deposit_status, :to => "administrativeMetadata",
           :at => [:hydrus, :depositStatus], :unique => true)
             
  delegate(:embargo, :to => "administrativeMetadata",
           :at => [:hydrus, :embargo], :unique => true)

  delegate(:embargo_option, :to => "administrativeMetadata",
           :at => [:hydrus, :embargo, :option], :unique => true)

  delegate(:license, :to => "administrativeMetadata",
           :at => [:hydrus, :license], :unique => true)

  delegate(:license_option, :to => "administrativeMetadata",
           :at => [:hydrus, :license, :option], :unique => true)

  delegate(:visibility, :to => "administrativeMetadata",
           :at => [:hydrus, :visibility], :unique => true)

  delegate(:visibility_option, :to => "administrativeMetadata",
           :at => [:hydrus, :visibility, :option], :unique => true)

  # roleMetadata
  delegate(:collection_owner, :to => "roleMetadata",
           :at => :collection_owner)

  delegate(:person_id, :to => "roleMetadata",
           :at => [:role, :person, :identifier])
  
  # Will be "item-depositor" for now per spec. Test will determine if it changes in the future.
  def self.default_role
    self.roles.last
  end
  
  def self.roles
    ["collection-manager", "collection-depositor", "item-depositor"]
  end    
  
  # Returns a hash of info needed for licenses in the APO.
  # Keys correspond to the license_option in the OM terminology.
  # Values are displayed in the web form.
  def self.license_types
    {'none'   => 'no license -- content creator retains exclusive rights',
     'varies' => 'varies -- select a default below; contributor may change it for each item',
     'fixed'  => 'required license -- apply the selected license to all items in the collection'}
  end
  
  # WARNING - the keys of this hash (which appear in the radio buttons in the colelction edit page) 
  #   are used in the collection model to trigger specific getting and setting behavior of embargo lengths
  #  if you change these keys here, you need to update the collection model as well
  def self.embargo_types
    {'none'   => 'No delay -- release all items as soon as they are deposited',
     'varies' => 'Varies -- select a release date per item, from "now" to a maximum of',
     'fixed'  => 'Fixed -- delay release of all items for'}
  end
  
  def self.visibility_types
    {'everyone' => 'Everyone -- all items in this collection will be public',
     'varies'   => 'Varies -- default is public, but you can choose to restrict some items to Stanford community',
     'stanford' => 'Stanford community -- all items will be visible only to Stanford-authenticated users'}
  end
  
  def self.embargo_terms
    {'6 months after deposit' => '6 months',
     '1 year after deposit'   => '1 year',
     '2 years after deposit'  => '2 years',
     '3 years after deposit'  => '3 years'}
  end
  
end
