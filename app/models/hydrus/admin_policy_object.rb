class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject

  include Hydrus::ModelHelper

  attr_accessor :publish
  
  validate :check_embargo_options, :if => :clicked_publish?
  
  def check_embargo_options
    if embargo_option != 'none' && embargo.blank?
      errors.add(:embargo, "must have a time period specified")
    end
  end

  def clicked_publish?
   to_bool(publish)
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
           
end
