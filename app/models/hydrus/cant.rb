module Hydrus::Cant

  # A utility method that raises an exception indicating that the
  # object cannot perform an action like open(), close(), approve(), etc.
  def cannot_do(action, cls = nil)
    msg = self.class == Class ?
          "object_type=#{self}, action=#{action}, pid=none" :
          "object_type=#{hydrus_class_to_s}, action=#{action}, pid=#{pid}"
    raise "Cannot perform action: #{msg}."
  end

end
