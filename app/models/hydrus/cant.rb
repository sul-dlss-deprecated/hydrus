# frozen_string_literal: true
module Hydrus::Cant

  # A utility method that raises an exception with a useful message indicating
  # that the object cannot perform an action like open(), close(), approve(),
  # etc. Typically, self is an instance Hydrus::Item or Hydrus::Collection;
  # however, in some cases self is a class. The message adjusts accordingly.
  def cannot_do(action)
    raise cannot_do_message(action)
  end

  def cannot_do_message(action)
    'Cannot perform action: ' <<
          (self.class == Class ?
          "object_type=#{self}, action=#{action}, pid=none." :
          "object_type=#{hydrus_class_to_s}, action=#{action}, pid=#{pid}.")
  end
end
