# A module to consolidate time-related logic, parsing, and formatting
# for the Hydrus application.
#
# Overview of the most common usages:
#
#   See DT_FORMATS for the available datetime formats.
#
#   When datetimes are returned as formatted strings, they are in
#   UTC on the backend (the XML) and Pacific on the front-end.
#   The latter occurs for the formats using the _display suffix.
#
#   HyTime.now      >> returns a DateTime for now, in UTC.
#
#   HyTime.now_FMT  >> Ditto, but as a String in the requested format.
#
#   HyTime.FMT(DT)  >> Returns a String in the requested format.
#                      The string is built using the DT object given,
#                      which can be a String or a DateTime. See the
#                      method for other options.

module HyTime

  DT_FORMATS = {
    # Back-end datetime formats for XML storage are based on iso8601.
    # For example: "2012-11-16T23:40:11Z".
    # Note that the :datetime format string produces the same string 
    # as calling iso8601() on a DateTime object.
    :date             => '%F',
    :time             => '%TZ',
    :datetime         => '%FT%TZ',
    :datetime_full    => '%FT%T.%LZ',  # With milliseconds.
    # Display formats -- for the web UI, for example.
    :date_display     => '%F',
    :time_display     => '%T',
    :datetime_display => '%F %T',
  }

  DEFAULT_TIMEZONE   = 'UTC'
  LOCAL_TIMEZONE     = 'Pacific Time (US & Canada)'
  DATE_PICKER_FORMAT = 'yyyy-mm-dd'

  # Returns DateTime object in the application's default timezone.
  def self.now()
    return DateTime.now.in_time_zone(DEFAULT_TIMEZONE).to_datetime
  end

  # Takes a String or DateTime-ish object, along with an options hash.
  # Return a string in the requested format (see DT_FORMATS).
  # If the requested format is a display format, the time is
  # converted to LOCAL_TIMEZONE.
  def self.formatted(dt, opts = {})
    # If given nil or empty string, just return empty string.
    return '' if dt.blank?
    # Convert the argument to a DateTime object.
    # If the user supplied a parsing format, use it; othwerise,
    # let to_datetime() figure it out.
    if opts[:parse] && dt.class == String
      dt = DateTime.strptime(dt, DT_FORMATS[opts[:parse]])
    else
      dt = dt.to_datetime
    end
    # If the DateTime is coming from user-entered input (ie, localtime)
    # adjust it to UTC.
    dt = dt - DateTime.local_offset if opts[:from_localtime]
    # Return string in the requested format, after adjusting to
    # the local timezone if caller requested a display format.
    f = opts[:format] || :datetime
    dt = dt.in_time_zone(LOCAL_TIMEZONE) if f.to_s[-8..-1] == '_display'
    return dt.strftime(DT_FORMATS[f])
  end

  # For each Hydrus datetime format, generate two HyTime methods:
  #   HyTime.FMT      >> HyTime.formatted(dt,         :format => :FMT).
  #   HyTime.now_FMT  >> HyTime.formatted(HyTime.now, :format => :FMT).
  DT_FORMATS.keys.each do |f|
    # HyTime.FMT
    define_singleton_method(f) do |*args|
      dt   = args[0]
      opts = args[1] || {}
      opts = opts.merge(:format => f)
      return formatted(dt, opts)
    end
    # HyTime.now_FMT
    define_singleton_method("now_#{f}") do
      return formatted(now, :format => f)
    end
  end

end
