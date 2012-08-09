# A mixin for is_publishable() and related methods.
module Hydrus::Publishable

  # This method is used to control whether validations are run.
  # The typical criterion is whether the object is published.
  # However, the is_publishable method needs to run validations on
  # unpublished objects. The @should_validate instance variable
  # provides a mechanism to short-circuit the typical logic.
  def should_validate
    return (@should_validate or is_published)
  end

  # Returns true only if the object is valid.
  # We want all validations to run, so we must set @should_validate accordingly.
  def is_publishable
    is_collection = self.class == Hydrus::Collection
    @should_validate = true
    apo.instance_variable_set('@should_validate', true) if is_collection
    v = valid?
    @should_validate = false
    apo.instance_variable_set('@should_validate', false) if is_collection
    return v
  end

end
