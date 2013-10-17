module Hydrus::UserWorkflowable

  # Returns true if the object is in the draft state.
  def is_draft?
    return object_status.nil? || object_status == 'draft'
  end
  
  # Returns true if the object status is any flavor of published. This status
  # is Hydrus-centric and aligns with the submitted_for_publish_time -- the
  # moment the user clicks Open/Approve/Publish in the UI. By contrast,
  # publish_time focuses on the time the object achieves the published
  # milestone in common accessioning.
  def is_published?
    return object_status && object_status[0..8] == 'published'
  end
  
  # Returns true if all required fields are filled in.
  def required_fields_completed?
    # Validate, and return true if all is OK.
    return true if validate!
    # If the intersection of the errors keys and the required fields
    # is empty, the required fields are complete and the validation errors
    # are coming from other problems.
    return (errors.keys & self.class::REQUIRED_FIELDS).size == 0
  end

end