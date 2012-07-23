class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject

  include Hydrus::ModelHelper

  # TODO: temporary fix until dor-services gem includes it in its APOs.
  include Dor::Processable
  
  validate :check_embargo_options, :if => :open_for_deposit?
  validate :check_license_options, :if => :open_for_deposit?
  validates :embargo_option, :presence => true, :if => :open_for_deposit?
  validates :license_option, :presence => true, :if => :open_for_deposit?

  def self.create(user)
    args = [user, 'adminPolicy', Dor::Config.ur_apo_druid]
    apo  = Hydrus::GenericObject.register_dor_object(*args)
    apo  = apo.adapt_to(Hydrus::AdminPolicyObject)
    apo.remove_relationship :has_model, 'info:fedora/afmodel:Dor_AdminPolicyObject'
    apo.assert_content_model
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
    :name => "administrativeMetadata",
    :type => Hydrus::AdministrativeMetadataDS,
    :label => 'Administrative Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "roleMetadata",
    :type => Hydrus::RoleMetadataDS,
    :label => 'Role Metadata',
    :control_group => 'M')

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
end
