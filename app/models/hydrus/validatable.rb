# A mixin used to control whether validation occurs.

module Hydrus::Validatable

  # This method is used to control whether validations are run.
  # The basic criterion is whether the object is beyond the draft stage.
  # However, we often want to run validations in advance of that in
  # order to inform user about missing attributes. The @should_validate 
  # instance variable provides a mechanism to short-circuit the typical logic.
  def should_validate
    return true if @should_validate
    return !is_draft
  end

  # Returns true only if the object is valid.
  # Used to run validations even if the object is still a draft.
  def validate!
    prev = @should_validate
    @should_validate = true
    v = valid?
    @should_validate = prev
    return v
  end

end
