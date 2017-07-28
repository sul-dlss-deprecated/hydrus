module Hydrus::GenericObjectStuff
  extend ActiveSupport::Concern
  included do
    include ActiveModel::Validations
  include Hydrus::ModelHelper
  include Hydrus::Validatable
  include Hydrus::Processable
  include Hydrus::Contentable
  include Hydrus::WorkflowDsExtension
  include Hydrus::Licenseable
  include Hydrus::UserWorkflowable
  include Hydrus::Eventable
  include Hydrus::Cant
  extend  Hydrus::Cant
  extend  Hydrus::Delegatable

  has_metadata(
    :name => "rightsMetadata",
    :type => Hydrus::RightsMetadataDS,
    :label => 'Rights Metadata',
    :control_group => "M")

  has_metadata(
    :name => "descMetadata",
    :type => Hydrus::DescMetadataDS,
    :label => 'Descriptive Metadata',
    :control_group => 'M')

  has_metadata(
    :name => "hydrusProperties",
    :type => Hydrus::HydrusPropertiesDS,
    :label => 'Hydrus Properties',
    :control_group => 'X')

  setup_delegations(
    # [:METHOD_NAME,              :uniq, :at... ]
    "descMetadata" => [
      [:title,                    true,  :main_title ],
      [:abstract,                 true   ],
      [:related_item_title,       false, :relatedItem, :titleInfo, :title],
      [:contact,                  true   ],
    ],
    "hydrusProperties" => [
      [:disapproval_reason,                 true   ],
      [:object_status,                      true   ],
      [:submitted_for_publish_time,         true   ],
      [:initial_submitted_for_publish_time, true   ],
      [:initial_publish_time,               true   ],
      [:submit_for_approval_time,           true   ],
      [:last_modify_time,                   true   ],
      [:item_type,                          true   ],
      [:object_version,                     true   ],
    ],
    "rightsMetadata" => [
      [:rmd_embargo_release_date, true,  :read_access, :machine, :embargo_release_date],
      [:terms_of_use,             true,  ],
    ],
  )
  end

  def apo
    @apo ||= (apo_pid ? admin_policy_object : Hydrus::AdminPolicyObject.new)
  end

  def apo_pid
    @apo_pid ||= admin_policy_object.id rescue nil
  end

  def related_items
    @related_items ||= descMetadata.find_by_terms(:relatedItem).map { |n|
      Hydrus::RelatedItem.new_from_node(n)
    }
  end


  # Since we need a custom setter, let's define the getter too
  # (rather than using delegation).
  def related_item_url
    descMetadata.relatedItem.location.url
  end

  # Takes an argument, typically an OM-ready hash. For example:
  #   {'0' => 'url_foo', '1' => 'url_bar'}
  # Modifies the URL values so that they all begin with a protocol.
  # Then assigns the entire thing to relatedItem.location.url.
  def related_item_url=(h)
    if h.kind_of?(Hash)
      h.keys.each { |k| h[k] = with_protocol(h[k]) }
    else
      h = with_protocol(h)
    end
    descMetadata.relatedItem.location.url = h
  end
  
  # Takes a string that is supposed to be a URI.
  # Returns the same string if it begins with a known protocol.
  # Otherwise, returns the string as an http URI.
  def with_protocol(uri)
    return uri if uri.blank?
    return uri if uri =~ /\A (http|https|ftp|sftp):\/\/ /x
    "http://" + uri
  end
  
  # Returns string representation of the class, minus the Hydrus:: prefix.
  # For example: Hydrus::Collection -> 'Collection'.
  def hydrus_class_to_s
    self.class.to_s.sub(/\AHydrus::/, '')
  end
  
  # After collections are published, further edits to the object are allowed.
  # This occurs without requiring the open_new_version() process used by Items.
  #
  # Here's an overview:
  #   - User open Collection for the first time.
  #   - Hydrus kicks off the assemblyWF/accessionWF pipeline.
  #   - Later, user edits Collection and clicks Save.
  #   - The save() method in Hydrus invokes publish_metadata().
  #   - Here we simply call super(), which delegates to the dor-services gem,
  #     provided that we are running in an environment intended to use the
  #     entire the assembly/accessioning/publishing pipeline.
  #   - Later, a nightly cron job (not built yet) will patrol Fedora, looking
  #     for modified Collections and APOs. If it finds any, it will open a new
  #     version and run the object through the pipeline.
  def publish_metadata
    return unless should_start_assembly_wf
    cannot_do(:publish_metadata) unless is_assemblable()
    publish_metadata_remotely
  end

  # Takes a list of fields that were changed by the user and
  # returns a string used in event logging. For example:
  #   "Item modified: title, abstract, license"
  def editing_event_message(fields)
    fs = fields.map { |e| e.to_s }.join(', ')
    "#{hydrus_class_to_s()} modified: #{fs}"
  end

  def is_item?
    self.class == Hydrus::Item
  end

  def is_collection?
    self.class == Hydrus::Collection
  end

  def is_apo?
    false
  end

end
