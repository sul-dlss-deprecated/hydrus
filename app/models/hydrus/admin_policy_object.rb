class Hydrus::AdminPolicyObject < Dor::AdminPolicyObject

  include Dor::Processable  # TODO: needed until dor-services gem includes in its APOs.
  include Hydrus::ModelHelper
  include Hydrus::Responsible
  include Hydrus::Publishable
  extend  Hydrus::Delegatable

  # has_relationship('governed_objects', :is_governed_by, :inbound => true)

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

  validates :pid, :is_druid => true
  validates :embargo_option, :presence => true, :if => :should_validate
  validates :license_option, :presence => true, :if => :should_validate
  validate  :check_embargo_options, :if => :should_validate
  validate  :check_license_options, :if => :should_validate

  setup_delegations(
    # [:METHOD_NAME,         :uniq, :at... ]
    "descMetadata" => [
      [:title,               true,  :main_title ],
    ],
    "roleMetadata" => [
      [:collection_manager,  false  ],
      [:person_id,           false, :role, :person, :identifier],
    ],
    "administrativeMetadata" => [
      [:deposit_status,      true,  :hydrus, :depositStatus],
      [:embargo,             true,  :hydrus, :embargo],
      [:embargo_option,      true,  :hydrus, :embargo, :option],
      [:license,             true,  :hydrus, :license],
      [:license_option,      true,  :hydrus, :license, :option],
      [:visibility,          true,  :hydrus, :visibility],
      [:visibility_option,   true,  :hydrus, :visibility, :option],
    ]
  )

  def initialize(*args)
    super
    @should_validate = false
  end

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
    # Add roleMetadata with current user as hydrus-collection-manager.
    apo.roleMetadata.add_person_with_role(user, 'hydrus-collection-manager')
    apo.roleMetadata.add_person_with_role(user, 'hydrus-collection-depositor')
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

  def is_published
    return is_open
  end

  def is_open
    return deposit_status == "open"
  end

  def self.roles
     return {
       'hydrus-collection-manager'  => "Manage collection",
       'hydrus-collection-reviewer' => "Review items",
       'hydrus-collection-item-depositor'      => "Deposit items",
       'hydrus-collection-viewer'   => "View items",
     }
  end

  def self.default_role
    return "hydrus-collection-item-depositor"
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
