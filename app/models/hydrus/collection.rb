class Hydrus::Collection < Hydrus::GenericObject

  extend  Hydrus::Delegatable
  extend Hydrus::SolrQueryable

  before_save :save_apo

  before_validation :remove_values_for_associated_attribute_with_value_none
  after_validation :strip_whitespace

  attr_accessor :item_counts

  setup_delegations(
    # [:METHOD_NAME,            :uniq,  :at... ]
    "hydrusProperties" => [
      [:requires_human_approval, true   ],
      [:collection_depositor, true   ],
      
    ],
  )

  has_relationship 'hydrus_items', :is_member_of_collection, :inbound => true

  # Creates a new Collection, sets up various defaults, saves and 
  # returns the object.
  def self.create(user)
    # Create the object, with the correct model.
    apo     = Hydrus::AdminPolicyObject.create(user)
    dor_obj = Hydrus::GenericObject.register_dor_object(user, 'collection', apo.pid)
    coll    = dor_obj.adapt_to(Hydrus::Collection)
    coll.collection_depositor=user.to_s
    coll.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Collection'
    coll.assert_content_model
    # Add some Hydrus-specific info to identityMetadata.
    coll.augment_identity_metadata(:collection)
    # Add event.
    coll.events.add_event('hydrus', user, 'Collection created')
    # Set defaults for visability, embargo, etc.
    coll.visibility_option_value = 'everyone'
    coll.embargo_option          = 'none'
    coll.requires_human_approval = 'no'
    coll.license_option          = 'none'
    # Save and return.
    coll.save(:no_edit_logging => true)
    return coll
  end

  # Returns true only if both the Collection and its APO are valid.
  # Note that we want both validations to run (even if the first fails)
  # so that APO error messages can be merged into those of the Collection.
  def valid?(*args)
    v1 = super
    v2 = apo.valid?
    errors.messages.merge!(apo.errors.messages)
    return v1 && v2
  end

  #################################
  # methods used to build sidebar

  def license_details_provided?
    validate! ? true : (errors.keys & [:license,:license_option]).size == 0
  end

  def embargo_details_provided?
    validate! ? true : (errors.keys & [:embargo,:embargo_option]).size == 0
  end

  ###########################
  
  # Returns true only if the Collection is unpublished and has no Items.
  def is_destroyable
    return not(is_published or has_items)
  end

  # Returns true only if the Collection has items.
  def has_items
    return hydrus_items.size > 0
  end

  # Open or close the Collection.
  # Opening also has the effect of publishing it.
  # Unlike open-close, which the user can toggle, publishing is irreversible.
  def publish(value)
    if to_bool(value)
      apo.deposit_status = 'open'
      # At the moment of publication, we refresh various titles.
      apo_title = "APO for #{title}"
      apo.identityMetadata.objectLabel = apo_title
      apo.title                        = apo_title
      identityMetadata.objectLabel     = title
      self.label                       = title     # The label in Fedora's foxml:objectProperties.
      apo.label                        = apo_title # Ditto.
      # Advance the workflow to record that the object has been published.
      s = 'submit'
      events.add_event('hydrus', @current_user, 'Collection opened')
      unless workflow_step_is_done(s)
        complete_workflow_step(s)
        approve() # Collections never require human approval, even when their Items do.
      end
    else
      apo.deposit_status = 'closed'
      events.add_event('hydrus', @current_user, 'Collection closed')
    end
  end

  def is_open
    return apo.is_open
  end

  def strip_whitespace
     strip_whitespace_from_fields [:title,:abstract,:contact]
  end

  def save_apo
    apo.save
  end

  def remove_values_for_associated_attribute_with_value_none
    self.embargo = nil if embargo_option == "none"
    self.license = nil if license_option == "none"
  end

  def roles_of_person(user)
    apo.roles_of_person(user)
  end

  def roles_of_person_for_ui(user)
    roles_of_person(user).collect {|role| Hydrus::AdminPolicyObject.roles[role]}
  end
  
  def add_empty_person_to_role *args
    apo.roleMetadata.add_empty_person_to_role *args
  end

  ####
  # Simple getters and settings forwarded to the APO.
  #
  # These are needed because ActiveFedora's delegate()
  # does not work when we need to delegate through to the APO.
  #
  # The conditional embargo and license methods allow us to set a 
  # single value for the embargo period and license from two separate 
  # HTML select controls, based on the value of a radio button.
  ####
  
  def owner
    depositors=apo.persons_with_role('hydrus-collection-depositor')
    depositors.size == 1 ? depositors.first : ''
  end
  
  def deposit_status *args
    apo.deposit_status *args
  end

  def embargo *args
    apo.embargo *args
  end

  def embargo= val
    apo.embargo= val
  end

  def embargo_option *args
    apo.embargo_option *args
  end

  def embargo_option= val
    apo.embargo_option= val
  end

  def embargo_fixed
    embargo_option == "fixed" ? embargo : ""
  end

  def embargo_varies
    embargo_option == "varies" ? embargo : ""
  end

  def embargo_fixed= val
    apo.embargo= val if embargo_option == "fixed"
  end

  def embargo_varies= val
    apo.embargo= val if embargo_option == "varies"
  end

  def license_fixed
    license_option == "fixed" ? license : ""
  end

  def license_varies
    license_option == "varies" ? license : ""
  end

  def license_fixed= val
    apo.license= val if license_option == "fixed"
  end

  def license_varies= val
    apo.license= val if license_option == "varies"
  end

  def license *args
    apo.license *args
  end

  def license= val
    apo.license= val
  end

  def license_option *args
    apo.license_option *args
  end

  def license_option= val
    apo.license_option= val
  end

  def person_id *args
    apo.person_id *args
  end

  def apo_person_roles
    return apo.person_roles
  end

  def apo_person_roles= val
    apo.person_roles= val
  end

  def apo_persons_with_role(role)
    return apo.persons_with_role(role)
  end

  def visibility *args
    apo.visibility *args
  end

  def visibility= val
    apo.visibility= val
  end

  def visibility_option *args
    apo.visibility_option *args
  end

  def visibility_option= val
    apo.visibility_option= val
  end

  def visibility_option_value *args
    opt = apo.visibility_option # fixed or varies
    vis = apo.visibility        # world or stanford
    return vov_lookup["#{opt}_#{vis}"]
  end

  def visibility_option_value= val
    opt, vis              = vov_lookup[val].split('_')
    apo.visibility_option = opt # fixed or varies
    apo.visibility        = vis # world or stanford
  end

  ####
  # Data structures.
  ####

  def vov_lookup
    return {
      'everyone'       => 'fixed_world',
      'varies'         => 'varies_world',
      'stanford'       => 'fixed_stanford',
      'fixed_world'    => 'everyone',
      'varies_world'   => 'varies',
      'fixed_stanford' => 'stanford',
    }
  end

  def tracked_fields
    return {
      :title       => [:title],
      :description => [:abstract],
      :embargo     => [:embargo_option, :embargo],
      :visibility  => [:visibility_option, :visibility],
      :license     => [:license_option, :license],
      :roles       => [:apo_person_roles],
    }
  end

  ####
  # A class method to run some SOLR queries to get Collections involving a
  # user, along with counts of Items in those Collections, broken down by their
  # workflow status.
  ####

  def self.initial_stats
    return {
      "published"        => 0,
      "waiting_approval" => 0,
      "draft"            => 0,
    }
  end

  def self.dashboard_stats(user)
    id_key = 'identityMetadata_objectId_t'

    # Get PIDs of the APOs where USER plays a role.
    h           = squery_apos_involving_user(user)
    resp, sdocs = issue_solr_query(h)
    apo_pids    = resp.docs.map { |doc| doc[id_key].first }

    # Get PIDs of the Collections governed by those APOs.
    # Use those PIDs as the keys to initalize a hash of stats.
    #   stats{COLL_PID} = {}
    h           = squery_collections_of_apos(apo_pids)
    resp, sdocs = issue_solr_query(h)
    stats       = Hash[ resp.docs.map { |doc|
      [doc[id_key].first, initial_stats()]
    } ]

    # Get counts of Items in those Collection, broken down by workflow status.
    # Add those counts to the stats hash.
    h           = squery_item_counts_of_collections(stats.keys)
    resp, sdocs = issue_solr_query(h)
    
    facet_pivot=resp.facet_counts['facet_pivot']
    if facet_pivot
      facet_pivot.values.first.each { |h|
        druid = h['value'].sub(/.+\/druid/, 'druid')
        h['pivot'].each { |p|
          status = p['value']
          n      = p['count']
          stats[druid] ||= {}
          stats[druid][status] = n
        }
      }
    end
    return stats
  end

end
