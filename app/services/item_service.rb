# frozen_string_literal: true

class ItemService
  def self.create(collection_pid, user, item_type = Hydrus::Application.config.default_item_type)
    new(collection: Hydrus::Collection.find(collection_pid),
        user: user).create(item_type)
  end

  def initialize(collection:, user:)
    @collection = collection
    @user = user
  end

  # Note: currently all items of of type :item. In the future,
  # the calling code can pass in the needed value.
  def create(item_type)
    validate!
    (@item = build_item(item_type)).tap do
      assign_to_collection
      add_depositor
      create_version
      create_event
      check_terms_of_deposit
      save_item
      send_notifications
    end
  end

  private

  attr_reader :collection, :user, :item

  # Make sure user can create items in the parent collection.
  def validate!
    raise "#{cannot_do_message(:create)}\nCollection '#{collection.pid}' is not open" unless collection.is_open
    raise "#{cannot_do_message(:create)}\nUser '#{user}' cannot create items in #{collection} #{collection.pid} according to APO #{collection.apo.pid}" unless Hydrus::Authorizable.can_create_items_in(user, collection)
  end

  # Create the object, with the correct model.
  # @return [Hydrus::Item]
  def build_item(item_type)
    registration_response = Hydrus::GenericObject.register_dor_object(user, 'item', collection.apo_pid)

    Hydrus::Item.find(registration_response[:pid]).tap do |item|
      workflow_client.create_workflow_by_name(item.pid, Dor::Config.hydrus.app_workflow, version: item.current_version)
      item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
      item.assert_content_model
      # Set the item_type, and add some Hydrus-specific info to identityMetadata.
      item.set_item_type(item_type)

      # Set object status.
      item.object_status = 'draft'
      item.terms_of_use = Hydrus::GenericObject.stanford_terms_of_use
    end
  end

  def workflow_client
    Dor::Config.workflow.client
  end

  # Add the Item to the Collection.
  def assign_to_collection
    item.collections << collection

    # Set default license, embargo, and visibility.
    item.license = collection.license
    if collection.embargo_option == 'fixed'
      item.embargo_date = HyTime.date_display(item.end_of_embargo_range)
    end
    vov = collection.visibility_option_value
    item.visibility = vov == 'stanford' ? vov : 'world'
  end

  # Add roleMetadata with current user as hydrus-item-depositor.
  def add_depositor
    item.roleMetadata.add_person_with_role(user, 'hydrus-item-depositor')
  end

  # Set version info.
  def create_version
    item.version_started_time = HyTime.now_datetime
    # The call to content_will_change! forces the instantiation of the versionMetadata XML.
    item.versionMetadata.content_will_change!
  end

  # Add event.
  def create_event
    item.events.add_event('hydrus', user, 'Item created')
  end

  # Check to see if this user needs to agree again for this new item, if not,
  # indicate agreement has already occured automatically
  def check_terms_of_deposit
    if item.requires_terms_acceptance(user.to_s, collection) == false
      item.accepted_terms_of_deposit = 'true'
      msg = 'Terms of deposit accepted due to previous item acceptance in collection'
      item.events.add_event('hydrus', user, msg)
    else
      item.accepted_terms_of_deposit = 'false'
    end
  end

  def save_item
    item.save(no_edit_logging: true, no_beautify: true)
  end

  def send_notifications
    item.send_new_deposit_email_notification
  end
end
