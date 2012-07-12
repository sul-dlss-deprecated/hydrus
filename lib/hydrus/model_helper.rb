module Hydrus
  module ModelHelper
  
    # strip whitespace from any attributes passed in
    def strip_whitespace_from_fields(fields)
      fields.each do |field|
        # this is needed since some attributes are actually a one element array
        if self.send(field).class == Array && self.send(field).size == 1 && self.send(field).first.respond_to?('strip')
          eval("self.#{field} = self.#{field}.first.strip")
        elsif self.send(field) != nil &&  self.send(field).respond_to?('strip')
          eval("self.#{field} = self.#{field}.strip")
        end
      end
    end
  
  end
end
