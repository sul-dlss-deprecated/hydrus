class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject

  include Hydrus::ModelHelper
  include Hydrus::Responsible
  include Hydrus::Validatable
  include Hydrus::Processable
  extend  Hydrus::Delegatable

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

  has_metadata(
    :name => "defaultObjectRights",
    :type => Hydrus::RightsMetadataDS,
    :label => 'Default Object Rights',
    :control_group => 'M',
    :autocreate => true)

  has_metadata(
    :name => "contentMetadata",
    :type => Dor::ContentMetadataDS,
    :label => 'Content Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "hydrusProperties",
    :type => Hydrus::HydrusPropertiesDS,
    :label => 'Hydrus Properties',
    :control_group => 'X')

  # Note: all other APO validation occurs in the Collection class.
  validates :pid, :is_druid => true

  setup_delegations(
    # [:METHOD_NAME,          :uniq, :at... ]
    "descMetadata" => [
      [:title,                true,  :main_title ],
    ],
    "roleMetadata" => [
      [:person_id,            false, :role, :person, :identifier],
      [:collection_depositor, true, :collection_depositor, :person, :identifier],
    ],
    "hydrusProperties" => [
      [:reviewed_release_settings, true   ],
      [:accepted_terms_of_deposit, true   ],
      [:object_version,            true   ],
    ]
  )

  def identityMetadata
    if defined?(super)
      super
    else
      datastreams['identityMetadata']
    end
  end

  def defaultObjectRights
    if defined?(super)
      super
    else
      datastreams['defaultObjectRights']
    end
  end

  def self.create(user)
    # Create the object, with the correct model.
    dconf = Dor::Config.hydrus
    args = [user, 'adminPolicy', dconf.ur_apo_druid]
    apo  = Hydrus::GenericObject.register_dor_object(:user => user, :object_type => 'adminPolicy', :admin_policy => dconf.ur_apo_druid)
    # Add minimal descMetadata with a title.
    apo.title = dconf.initial_apo_title
    apo.label = apo.title
    # Add roleMetadata with current user as hydrus-collection-manager.
    rmd = apo.roleMetadata
    rmd.add_person_with_role(user, 'hydrus-collection-manager')
    rmd.add_person_with_role(user, 'hydrus-collection-depositor')
    rmd.add_group_with_role("dlss:pmag-staff", "dor-apo-manager")
    rmd.add_group_with_role("dlss:developers", "dor-apo-manager")
    # Create defaultObjectRights datastream ... by mentioning it.
    apo.defaultObjectRights.content_will_change!
    # Add the references agreement to the APO's RELS-EXT.
    apo.add_relationship(:references_agreement, Hydrus::Application.config.default_apo_agreement) if Hydrus::Application.config.default_apo_agreement
    # Save and return.
    apo.save!
    return apo
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

  def hydrus_class_to_s
    "apo"
  end

  def is_assemblable
    true
  end

end
