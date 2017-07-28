module Hydrus

  module ModelHelper

    # Returns the object type as a string: item, collection, or adminPolicy.
    def object_type
      identityMetadata.objectType.first || self.class.to_s.demodulize.downcase
    end

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
      (val == "true" || val == true || val == 'yes')
    end

    # Takes a delimited string (eg, of keywords as entered on Item edit page).
    # Returns an array of elements obtained by parsing the string.
    # Allowed delimiters: comma, semi-colon, newlines.
    def self.parse_delimited(cds)
      cds.split(/[,;\n\r]/).each { |s| s.strip! }.select { |s| s.length > 0 }
    end

    # Takes two values.
    # Returns true if they are equal, ignoring leading and trailing whitespace
    # for values that respond to strip().
    def equal_when_stripped?(v1, v2)
      v1 = v1.strip if v1.respond_to?(:strip)
      v2 = v2.strip if v2.respond_to?(:strip)
      v1 == v2
    end

  end

end
