# A mixin for is_publishable() and related methods.

module Hydrus::Publishable

  # This method is used to control whether validations are run.
  # The typical criterion is whether the object is published.
  # However, the is_publishable method needs to run validations on
  # unpublished objects. The @should_validate instance variable
  # provides a mechanism to short-circuit the typical logic.
  def should_validate
    return true if @should_validate
    return true if self.class == Hydrus::AdminPolicyObject
    return is_submitted
  end
  
  def is_publishable
    is_published ? true : (to_bool(requires_human_approval) && !is_collection? ? validate! && is_approved : validate!)
  end
  
  # Returns true only if the object is valid.
  # We want all validations to run, so we must set @should_validate accordingly.
  def validate!
    prev = @should_validate
    @should_validate = true
    v = valid?
    @should_validate = prev
    return v
  end

end
