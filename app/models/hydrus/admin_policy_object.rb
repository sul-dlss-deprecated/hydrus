class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject 
  
  has_metadata(
    :name => "administrativeMetadata",
    :type => Hydrus::AdministrativeMetadataDS,
    :label => 'Administrative Metadata',
    :control_group => 'M')

end
