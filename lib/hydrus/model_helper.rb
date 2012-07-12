module Hydrus
  module ModelHelper
  
    # strip whitespace from any attributes passed in
    def strip_whitespace_from_fields(fields)
      fields.each do |field|
        eval("self.#{field} = self.#{field}.strip") if self.send(field).respond_to?('strip')  # we can't just call a strip directly on the field due to OM?
      end
    end
  
  end
end
