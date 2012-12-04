class Hydrus::Collection < Hydrus::GenericObject

  extend Hydrus::Delegatable
  extend Hydrus::SolrQueryable

  before_save :save_apo

  REQUIRED_FIELDS = [:title, :abstract, :contact]
  REQUIRED_FIELDS.each {|field| validates field, :not_empty => true, :if => :should_validate}

  before_validation :remove_values_for_associated_attribute_with_value_none
  after_validation :cleanup_usernames
  after_validation :strip_whitespace

  validates :embargo_option, :presence => true, :if => :should_validate
  validates :license_option, :presence => true, :if => :should_validate
  validate  :check_embargo_options
  validate  :check_license_options

  def check_embargo_options
    if embargo_option != 'none' && embargo_terms.blank?
      errors.add(:embargo, "must have a maximum time period specified when the varies or fixed option is selected")
    end
  end

  def check_license_options
    if license_option != 'none' && license.blank?
      errors.add(:license, "must be specified when the varies or fixed license option is selected")
    end
  end

  attr_accessor :item_counts

  setup_delegations(
    # [:METHOD_NAME,             :uniq,  :at... ]
    "hydrusProperties" => [
      [:requires_human_approval, true   ],
      [:embargo_option,          true,  ],
      [:embargo_terms,           true,  ],
      [:license_option,          true,  ],
      [:visibility_option,       true,  ],
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
    coll.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Collection'
    coll.assert_content_model
    # Set the item_type, and add some Hydrus-specific info to identityMetadata.
    # Note that item_type can vary for items but is always :collection here.
    itype = :collection
    coll.item_type = itype.to_s
    coll.augment_identity_metadata(itype)
    # Add event.
    coll.events.add_event('hydrus', user, 'Collection created')
    # Set defaults for visability, embargo, etc.
    coll.visibility_option_value = 'everyone'
    coll.embargo_option          = 'none'
    coll.embargo_terms           = ''
    coll.requires_human_approval = 'no'
    coll.license_option          = 'none'
    # Set object status.
    coll.object_status = 'draft'
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

  # method used to build sidebar
  def license_details_provided?
    validate! ? true : (errors.keys & [:license,:license_option]).size == 0
  end

  # method used to build sidebar
  def embargo_details_provided?
    validate! ? true : (errors.keys & [:embargo,:embargo_option]).size == 0
  end

  # Returns true only if the Collection is unpublished and has no Items.
  def is_destroyable
    return not(is_published or has_items)
  end

  # Returns true only if the Collection has items.
  def has_items
    return hydrus_items.size > 0
  end

  # Returns true if the collection is open.
  def is_open
    return object_status == 'published_open'
  end

  # Returns true if the collection can be opened.
  def is_openable
    return false if is_open
    return validate!
  end

  # Returns true if the collection can be closed.
  def is_closeable
    return is_open
  end

  # Returns true if the object is ready for common assembly.
  # It's not strictly necessary to involve validate!, but it provides extra insurance.
  def is_assemblable
    return false unless is_open
    return validate!
  end

  # the users who will receive email notifications when a collection is opened or closed
  def recipients_for_collection_update_emails
    (
      apo.persons_with_role("hydrus-collection-item-depositor") +
      apo.persons_with_role("hydrus-collection-manager") +
      apo.persons_with_role("hydrus-collection-depositor")
    ).to_a.join(', ')
  end

  # Opens the collection.
  # The first time a collection is opened, it is also published.
  # After that, the user can toggle the open-closed state, but
  # the publishing step is irreversible.
  def open
    cannot_do(:open) unless is_openable()

    # Determine if this is the first time the collection is being opened.
    first_time = is_draft()

    self.object_status = 'published_open'
    events.add_event('hydrus', @current_user, 'Collection opened')

    # Also, at the moment of publication, we refresh various titles and labels.
    # Note that the two label attributes reside in Fedora's foxml:objectProperties.
    refresh_titles

    # If needed, advance the workflow to record that the object has been published.
    # At this time we can also approve the collection, because collections never
    # require human approval, even when their items do.
    if first_time
      self.publish_time = HyTime.now_datetime
      complete_workflow_step('submit')
      complete_workflow_step('approve')
      start_common_assembly()
    end

    # Send email.
    send_publish_email_notification(true)
  end

  # Closes the collection.
  def close
    cannot_do(:close) unless is_closeable
    self.object_status = 'published_closed'
    events.add_event('hydrus', @current_user, 'Collection closed')
    send_publish_email_notification(false)
  end

  # update APO defaultObjectRights datastream from collection objectRights
  def refresh_default_object_rights
    apo.defaultObjectRights.content = self.rightsMetadata.to_xml
  end

  # update various apo titles and collection titles from value set by user
  def refresh_titles
    apo_title = "APO for #{title}"
    apo.identityMetadata.objectLabel = apo_title
    apo.title                        = apo_title
    identityMetadata.objectLabel     = title
    self.label                       = title
    apo.label                        = apo_title
  end

  def send_invitation_email_notification(new_depositors)
    return if new_depositors.blank?
    email=HydrusMailer.invitation(:to =>  new_depositors, :object =>  self)
    email.deliver unless email.to.blank?
  end

  def send_publish_email_notification(value)
    return if recipients_for_collection_update_emails.blank?
    meth = value ? 'open' : 'close'
    email = HydrusMailer.send("#{meth}_notification", :object => self)
    email.deliver unless email.to.blank?
  end

  # returns a hash of depositors for this collection that have accepted the terms of deposit for an item in that collection
  def users_accepted_terms_of_deposit
    result={}
    hydrusProperties.find_by_terms(:users_accepted_terms_of_deposit,:user).each do |node|
      result.merge!(node.content => node['dateAccepted'])
    end
    return result
  end

  # Takes a user and a datetime string.
  # A user accepts the terms of deposit: either update the time (if
  # user has done this before) or add a new node.
  # This XML logic probably belongs in the hydrusProperties datastream class.
  def accept_terms_of_deposit(user, datetime_accepted)
    existing_user = hydrusProperties.ng_xml.xpath("//user[text()='#{user}']")
    if existing_user.size == 0
      hydrusProperties.insert_user_accepting_terms_of_deposit(user, datetime_accepted)
    else
      existing_user[0]['dateAccepted'] = datetime_accepted
    end
    save
  end

  def strip_whitespace
     strip_whitespace_from_fields [:title,:abstract,:contact]
  end

  # Rewrites the APO.person_roles, converting any email addresses to SUNET IDs.
  def cleanup_usernames
    self.apo_person_roles = cleaned_usernames
  end

  # Processes the APO.person_roles hash.
  # Converts all users names that are email addresses into SUNET IDs
  # by removing text following the @ sign. In addition, the
  # values of the hash are joined by commas, so that the hash is
  # ready for assignment back to apo_person_roles.
  def cleaned_usernames
    result = {}
    apo_person_roles.each { |role, users|
      ids = users.map { |u| u.split('@').first }
      result[role] = ids.join(',')
    }
    return result
  end

  def save_apo
    refresh_titles
    refresh_default_object_rights
    apo.save
  end

  def remove_values_for_associated_attribute_with_value_none
    self.embargo_terms = nil if embargo_option == "none"
    self.license       = nil if license_option == "none"
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
  # Simple getters and settings
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

  def collection_depositor *args
    apo.collection_depositor *args
  end

  def collection_depositor= val
    apo.collection_depositor= val
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

  # Embargo and license getters and setters to support the complex
  # forms in the UI.

  def embargo_fixed
    embargo_option == "fixed" ? embargo_terms : ""
  end

  def embargo_varies
    embargo_option == "varies" ? embargo_terms : ""
  end

  def embargo_fixed= val
    self.embargo_terms= val if embargo_option == "fixed"
  end

  def embargo_varies= val
    self.embargo_terms= val if embargo_option == "varies"
  end

  def license_fixed
    license_option == "fixed" ? license : ""
  end

  def license_varies
    license_option == "varies" ? license : ""
  end

  def license_fixed= val
    self.license= val if license_option == "fixed"
  end

  def license_varies= val
    self.license= val if license_option == "varies"
  end

  # Visibility getters and setters.
  #
  #   visibility_option_value   Used by the Collection views and controllers.
  #                             These methods then call the other getters/setters.
  #
  #   visibility                Defined below. 
  #                             Reads/modifies rightsMetadata.
  #                             Not sure why the getter returns and Array.
  #
  #   visibility_option         Defined via delegation.
  #                             Reads/modifies hydrusProperties.

  def visibility_option_value *args
    opt = visibility_option     # fixed or varies
    vis = visibility.first      # world or stanford
    return vov_lookup["#{opt}_#{vis}"]
  end

  def visibility_option_value= val
    opt, vis               = vov_lookup[val].split('_')
    self.visibility_option = opt     # fixed or varies
    self.visibility        = vis     # world or stanford
  end

  def visibility
    return ["world"] if rightsMetadata.has_world_read_node
    return rightsMetadata.group_read_nodes.map { |n| n.text }
  end

  def visibility=(val)  # val = world or stanford
    rightsMetadata.update_access_blocks(val)
  end

  ####
  # Data structures.
  ####

  def vov_lookup
    lookup = {
      'everyone' => 'fixed_world',
      'varies'   => 'varies_world',
      'stanford' => 'fixed_stanford',
    }
    return lookup.merge(lookup.invert)
  end

  def tracked_fields
    return {
      :title       => [:title],
      :description => [:abstract],
      :embargo     => [:embargo_option, :embargo_terms],
      :visibility  => [:visibility_option, :visibility],
      :license     => [:license_option, :license],
      :roles       => [:apo_person_roles],
    }
  end

  ####
  # Some class method to run some SOLR queries to get Collections involving a
  # user, along with counts of Items in those Collections, broken down by their
  # workflow status.
  ####

  # Takes a user name.
  # Returns a hash of item counts (broken down by object status) for
  # collections in which the USER plays a role.
  def self.dashboard_stats(user)
    # Get PIDs of the APOs in which USER plays a role.
    apo_pids = apos_involving_user(user)
    return {} if apo_pids.size == 0

    # Get PIDs of the Collections governed by those APOs.
    coll_pids = collections_of_apos(apo_pids)
    return {} if coll_pids.size == 0

    # Returns the item counts for those collections.
    return item_counts_of_collections(coll_pids)
  end

  # Takes a user name.
  # Returns an array druids for the APOs in which USER plays a role.
  def self.apos_involving_user(user)
    return [] unless user
    h           = squery_apos_involving_user(user)
    resp, sdocs = issue_solr_query(h)
    return get_druids_from_response(resp)
  end

  # Takes an array of APO druids.
  # Returns an array of druids for the Collections governed by those APOs.
  def self.collections_of_apos(apo_pids)
    h           = squery_collections_of_apos(apo_pids)
    resp, sdocs = issue_solr_query(h)
    return get_druids_from_response(resp)
  end

  # Returns a hash with all Item object_status values as the
  # keys and zeros as the values.
  def self.initial_item_counts
    return Hash[ status_labels(:item).keys.map { |s| [s,0]  } ]
  end

  # Takes an array of Collection druids.
  # Returns a hash-of-hashes of item counts, broken down by object status.
  # See unit test for an example.
  def self.item_counts_of_collections(coll_pids)
    # Initalize the hash of item counts.
    counts = Hash[ coll_pids.map { |cp| [cp, initial_item_counts()] } ]

    # Run SOLR query to get items counts.
    h = squery_item_counts_of_collections(counts.keys)
    resp, sdocs = issue_solr_query(h)

    # Extract needed counts from SOLR response and put them into to the hash.
    # In the loop below, each fc hash looks like this example:
    #   {
    #     "value" => "info:fedora/druid:oo000oo0003",
    #     "pivot" => [
    #       { "value" => "draft",             "count" => 1 },
    #       { "value" => "awaiting_approval", "count" => 3 },
    #       { "value" => "published",         "count" => 0 },
    #     ]
    #   }
    get_facet_counts_from_response(resp).each { |fc|
      druid = fc['value'].split('/').last
      fc['pivot'].each { |p|
        status = p['value']
        n      = p['count']
        counts[druid] ||= initial_item_counts()
        counts[druid][status] = n
      }
    }

    # Prune the inner hashes, removing keys if the count is zero.
    counts.each do |druid, h|
      h.delete_if { |k,v| v == 0 }
    end

    return counts
  end

  # Takes a SOLR response.
  # Returns an array of druids corresponding to the documents.
  # Written as a separate method for testing purposes.
  def self.get_druids_from_response(resp)
    k = 'identityMetadata_objectId_t'
    return resp.docs.map { |doc| doc[k].first }
  end

  # Takes a SOLR response.
  # Returns an array of hashes containing the needed facet counts.
  # Written as a separate method for testing purposes.
  def self.get_facet_counts_from_response(resp)
    return resp.facet_counts['facet_pivot'].values.first
  end

  # Returns an array-of-arrays containing the collection's @item_counts
  # information. Instead of using object_status values, the info
  # uses human readable labels for the UI. See unit test for an example.
  def item_counts_with_labels
    return item_counts.map { |s, n| [n, Hydrus::GenericObject.status_label(:item, s)] }
  end

end
