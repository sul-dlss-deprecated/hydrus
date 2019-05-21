class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject
  include Hydrus::ModelHelper
  include Hydrus::Responsible
  include Hydrus::Validatable
  include Hydrus::Processable
  include Hydrus::Contentable
  include Dor::Publishable
  extend  Hydrus::Delegatable

  has_metadata(
    name: 'descMetadata',
    type: Hydrus::DescMetadataDS,
    label: 'Descriptive Metadata',
    control_group: 'M'
  )

  has_metadata(
    name: 'roleMetadata',
    type: Hydrus::RoleMetadataDS,
    label: 'Role Metadata',
    control_group: 'M'
  )

  has_metadata(
    name: 'defaultObjectRights',
    type: Hydrus::RightsMetadataDS,
    label: 'Default Object Rights',
    control_group: 'M',
    autocreate: true
  )

  has_metadata(
    name: 'contentMetadata',
    type: Dor::ContentMetadataDS,
    label: 'Content Metadata',
    control_group: 'M'
  )

  has_metadata(
    name: 'hydrusProperties',
    type: Hydrus::HydrusPropertiesDS,
    label: 'Hydrus Properties',
    control_group: 'X'
  )

  # Note: all other APO validation occurs in the Collection class.
  validates :pid, is_druid: true

  setup_delegations(
    # [:METHOD_NAME,          :uniq, :at... ]
    'descMetadata' => [
      [:title,                true,  :main_title],
    ],
    'roleMetadata' => [
      [:person_id,            false, :role, :person, :identifier],
      [:collection_depositor, true, :collection_depositor, :person, :identifier],
    ],
    'hydrusProperties' => [
      [:reviewed_release_settings, true],
      [:accepted_terms_of_deposit, true],
      [:object_version,            true],
    ]
  )

  def initialize(*args)
    super
  end

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
    response = Hydrus::GenericObject.register_dor_object(*args)
    apo = Hydrus::AdminPolicyObject.find(response[:pid])
    workflow_client.create_workflow_by_name(response[:pid], Dor::Config.hydrus.app_workflow)

    apo.remove_relationship :has_model, 'info:fedora/afmodel:Dor_AdminPolicyObject'
    apo.assert_content_model
    # Add minimal descMetadata with a title.
    apo.title = dconf.initial_apo_title
    apo.label = apo.title
    # Add roleMetadata with current user as hydrus-collection-manager.
    rmd = apo.roleMetadata
    rmd.add_person_with_role(user, 'hydrus-collection-manager')
    rmd.add_person_with_role(user, 'hydrus-collection-depositor')
    %w[sdr:developer sdr:service-manager sdr:metadata-staff].each do |group|
      rmd.add_group_with_role(group, 'dor-apo-manager')
    end
    # Add the references agreement to the APO's RELS-EXT.
    apo.add_relationship(:references_agreement, 'info:fedora/druid:mc322hh4254')
    # Save and return.
    apo.save!
    apo
  end

  # Lazy initializers for instance variables.
  # We cannot set these value within a constructor, because
  # some Items and Collections are obtained in ways that won't call
  # our constructor code -- for example, Hydrus::Item.find().
  def current_user
    (@current_user ||= '')
  end

  def current_user=(val)
    @current_user = val
  end

  def hydrus_class_to_s
    'apo'
  end

  def is_apo?
    true
  end

  def is_item?
    false
  end

  def is_collection?
    false
  end

  def is_assemblable
    true
  end

  # Returns a hash of info needed for licenses in the APO.
  # Keys correspond to the license_option in the OM terminology.
  # Values are displayed in the web form.
  def self.license_types
    {
      'none'   => 'no license',
      'varies' => 'varies -- contributor may select a license for each item, with a default of',
      'fixed'  => 'required license -- applies to all items in the collection',
    }
  end

  # WARNING - the keys of this hash (which appear in the radio buttons in the
  # colelction edit page) are used in the collection model to trigger specific
  # getting and setting behavior of embargo lengths. If you change these keys
  # here, you need to update the collection model as well
  def self.embargo_types
    { 'none'   => 'No delay -- release all items as soon as they are deposited',
      'varies' => 'Varies -- select a release date per item, from "now" to a maximum of',
      'fixed'  => 'Fixed -- delay release of all items for' }
  end

  def self.visibility_types
    { 'everyone' => 'Everyone -- all items in this collection will be public',
      'varies'   => 'Varies -- default is public, but you can choose to restrict some items to Stanford community',
      'stanford' => 'Stanford community -- all items will be visible only to Stanford-authenticated users' }
  end

  def self.embargo_terms
    { '6 months after deposit' => '6 months',
      '1 year after deposit'   => '1 year',
      '2 years after deposit'  => '2 years',
      '3 years after deposit'  => '3 years' }
  end
end
