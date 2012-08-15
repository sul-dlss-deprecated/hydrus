module Hydrus

  module ModelHelper

    # Takes an array of OM terms.
    # Removes leading and trailing whitespace from the values referenced
    # by those terms.
    def strip_whitespace_from_fields(terms)
      terms.each do |term|
        v = send(term)
        send(:"#{term}=", v.strip) if v.respond_to?(:strip)
      end
    end

    def to_bool(val)
      return (val == "true" || val == true || val == 'yes')
    end

  end

end
