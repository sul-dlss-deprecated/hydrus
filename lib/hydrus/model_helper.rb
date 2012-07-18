module Hydrus
  module ModelHelper
  
    # strip whitespace from any attributes passed in
    def strip_whitespace_from_fields(fields)
      fields.each do |field|
        eval("self.#{field} = self.#{field}.strip") if self.send(field).respond_to?('strip')  # we can't just call a strip directly on the field due to OM?
      end
    end
    
    def to_bool(value)
      value == "true" || value == true ? true : false
    end
  
  end
end
