module Hydrus::UserWorkflowable
  # Returns true if the object is in the draft state.
  def is_draft
    object_status == 'draft'
  end

  # Returns true if the object status is any flavor of published. This status
  # is Hydrus-centric and aligns with the submitted_for_publish_time -- the
  # moment the user clicks Open/Approve/Publish in the UI. By contrast,
  # publish_time focuses on the time the object achieves the published
  # milestone in common accessioning.
  def is_published
    object_status[0..8] == 'published'
  end

  # Returns true if all required fields are filled in.
  def required_fields_completed?
    # Validate, and return true if all is OK.
    return true if validate!
    # If the intersection of the errors keys and the required fields
    # is empty, the required fields are complete and the validation errors
    # are coming from other problems.
    (errors.keys & self.class::REQUIRED_FIELDS).size == 0
  end

  # Compares the current object to its old self in fedora.
  # Returns the list of fields for which differences are found.
  # The comparisons are driven by the hash-of-arrays returned by
  # tracked_fields() from the Item or Collection class.
  def changed_fields
    old = old_self()
    cfs = []
    tracked_fields.each do |k, fs|
      next if fs.all? { |f| equal_when_stripped? old.send(f), self.send(f) }
      cfs.push(k)
    end
    cfs
  end

  # Returns the version of the object as it exists in fedora.
  def old_self
    @cached_old_self ||= self.class.find(pid)
  end
end
