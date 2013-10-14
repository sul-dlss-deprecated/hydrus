module Hydrus::Embargoable
  extend ActiveSupport::Concern
  include Hydrus::EmbargoMetadataDsExtension

  included do
    validate  :embargo_date_is_well_formed
    validate  :embargo_date_in_range
    validate  :check_visibility_not_reduced
  end

  # During subsequent versions the user not allowed to reduce visibility.
  def check_visibility_not_reduced
    return if is_initial_version?
    v = visibility
    return if v == ['world']
    return if v == [prior_visibility]
    # ap({
    #   :visibility         => visibility,
    #   :prior_visibility   => prior_visibility,
    #   :embargo_date       => embargo_date,
    # })
    msg = "cannot be reduced in subsequent versions"
    errors.add(:visibility, msg)
  end

  # Return's true if the user can modify the Item visibility.
  #   - Collection must allow it.
  #   - Initial version: anything goes.
  #   - Subsequent versions: visibility cannot be reduced from world to stanford.
  def visibility_can_be_changed
    return false unless collection.visibility_option == 'varies'
    return true  if is_initial_version?
    return false if prior_visibility == 'world'
    return true
  end

  # Returns visibility as an array -- typically either ['world'] or ['stanford'].
  # Embargo status determines which datastream is used to obtain the information.
  def visibility
    ds = is_embargoed? ? embargoMetadata : rightsMetadata
    return ["world"] if ds.has_world_read_node
    return ds.group_read_nodes.map { |n| n.text }
  end

  # Takes a visibility -- typically 'world' or 'stanford'.
  # Modifies the embargoMetadata and rightsMetadata based on that visibility
  # values, along with the embargo status.
  # Do not call this directly from the UI. Instead, use embarg_visib=().
  def visibility= val
    if is_embargoed?
      # If embargoed, we set access info in embargoMetadata.
      embargoMetadata.initialize_release_access_node(:generic)
      embargoMetadata.update_access_blocks(val)
      # And we clear our read access in rightsMetadata and add an explicit <none/> block.
      rightsMetadata.deny_read_access
    else
      # Otherwise, just set access info in rightsMetadata.
      # The embargoMetadata should not exist at this point.
      rightsMetadata.update_access_blocks(val)
    end
  end

  # Returns true if the Item's embargo_date can be changed, based on the
  # Collection setting, the version, and whether the Item has an embargo_date.
  def embargo_can_be_changed
    # Collection must allow it.
    return false unless collection.embargo_option == 'varies'
    # Behavior varies by version.
    if is_initial_version?
      return true
    else
      # In subsequent versions, Item must
      #   - have an existing embargo
      #   - that has a max embargo date some time in the future
      return false unless is_embargoed?
      return HyTime.now < end_of_embargo_range.to_datetime
    end
  end

  # Takes a hash with the following keys and possible values:
  #
  #     'embargoed'  => 'yes'
  #                     'no'
  #                     nil            # Form did not offer embargo choice.
  #
  #     'date'       => 'YYYY-MM-DD'
  #                     nil            # Ditto.
  #
  #     'visibility' => 'world'
  #                     'stanford'
  #                     nil            # Ditto.
  #
  # Given that hash, we call the embargo_date and visibility
  # setters. The UI invovkes this combined setter (not the individual
  # setters), because we want to ensure that the individual setters
  # are called in the desired order. This is necessary because the
  # visibility setter needs to know the Item's embargo status.
  def embarg_visib=(opts)
    e  = opts['embargoed']
    d  = opts['date']
    v  = opts['visibility'] || visibility.first
    dt = to_bool(e) ? d : ''
    self.embargo_date = dt unless e.nil?
    self.visibility   = v
  end

  # Returns true if the Item is embargoed.
  def is_embargoed?
    return not(embargo_date.blank?)
  end

  # Returns the embargo date from the embargoMetadata, not the rightsMetadata.
  # We don't use the latter because it is a convenience copy used by the PURL app.
  # Switched to returning '' rather than nil, because we were getting extraneous
  # editing events related to embargo_date (old value of '' and new value of nil).
  def embargo_date
    ed = embargoMetadata ? embargoMetadata.release_date : ''
    ed = '' if ed.nil?
    return ed
  end

  # Sets the embargo date in both embargoMetadata and rightsMetadata.
  # The new value is assumed to be expressed in the local time zone.
  # If the new date is blank, nil, or not parsable as a datetime,
  # the embargoMetadata datastream is deleted.
  #
  # Notes:
  #   - We do not call this directly from the UI. Instead, the embarg_visib
  #     setter is used (see its notes).
  #   - If the argument is not parsable as a datetime, we set an instance
  #     variable, which we use latter (during validations) to tell the
  #     user that the embargo date was malformed. This awkwardness could
  #     be avoided if we simplify the UI, removing the embargo radio button.
  def embargo_date= val
    if HyTime.is_well_formed_datetime?(val)
      ed = HyTime.datetime(val, :from_localzone => true)
    elsif val.blank?
      ed = nil
    else
      @embargo_date_was_malformed = true
      return
    end
    if ed.blank?
      # Note: we must removed the embargo date from embargoMetadata (even
      # though we also delete the entire datastream), because the former
      # happens right away (which we need) and the latter appears to
      # happen later (maybe during save).
      rightsMetadata.remove_embargo_date
      embargoMetadata.remove_embargo_date
      embargoMetadata.delete
    else
      self.rmd_embargo_release_date = ed
      embargoMetadata.release_date  = ed
      embargoMetadata.status        = 'embargoed'
    end
  end

  # Adds an embargo_date validation error if the prior call to
  # the embargo_date setter determined that the date supplied by
  # the user had in invalid format.
  def embargo_date_is_well_formed
    return unless @embargo_date_was_malformed
    msg = "must be in #{HyTime::DATE_PICKER_FORMAT} format"
    errors.add(:embargo_date, msg)
  end

  # Validates that the embargo date set by the user falls within the allowed range.
  # Note: the embargo date picker does not offer the user the choice of setting a
  # date in the past; nonetheless, it is possible for a valid object to have a
  # past embargo date, because the nightly job that removes embargoMetadata
  # once the date has passed might not have run yet.
  def embargo_date_in_range
    return unless is_embargoed?
    b  = beginning_of_embargo_range.to_datetime
    e  = end_of_embargo_range.to_datetime
    dt = embargo_date.to_datetime
    unless (b <= dt and dt <= e)
      b = HyTime.date_display(b)
      e = HyTime.date_display(e)
      errors.add(:embargo_date, "must be in the range #{b} through #{e}")
    end
  end

  # Returns a datetime string for the start of the embargo range.
  # Has item ever been published?
  #   - No:  returns now.
  #   - Yes: returns time of initial submission for publication.
  # Note: If the item has been published this method can return
  # dates in the past; for that reason, we do not use this method
  # to definie the beginning date allowed by the embargo date picker.
  def beginning_of_embargo_range
    return initial_submitted_for_publish_time || HyTime.now_datetime
  end

  # Parses embargo_terms (eg, "2 years") into its number and time-unit parts.
  # Uses those parts to add a time increment (eg 2.years) to the beginning
  # of the embargo range. Returns that result as a datetime string.
  def end_of_embargo_range
    n, time_unit = collection.embargo_terms.split
    dt = beginning_of_embargo_range.to_datetime + n.to_i.send(time_unit)
    return HyTime.datetime(dt)
  end

end