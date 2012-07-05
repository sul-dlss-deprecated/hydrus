class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject 
  
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

  delegate :embargo, :to => "administrativeMetadata", :at => [:hydrus, :embargo], :unique => true
  delegate :release, :to => "administrativeMetadata", :at => [:hydrus, :release], :unique => true
  delegate :license, :to => "administrativeMetadata", :at => [:hydrus, :license], :unique => true
  delegate :manager, :to => "roleMetadata", :at => [:manager, :person, :name]

end
