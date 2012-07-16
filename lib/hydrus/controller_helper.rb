module Hydrus

  module ControllerHelper

    # Takes a comma-delimited string of keywords/topics.
    # Returns a hash like this: { 0 => 'foo', 1 => 'bar bar', etc. }
    # Leading and trailing whitespace is removed from the keywords.
    def parse_keywords(kws)
      Hash[ kws.strip.split(/\s*,\s*/).each_with_index.map { |kw,i| [i,kw] } ]
    end

  end

end
