module Hydrus::Versionable
  extend ActiveSupport::Concern

  included do

  end

  # Returns the Item's current version number, 1..N.
  def version_id
    return current_version
  end

  # Returns the Item's current version tag, eg v2.2.0.
  def version_tag
    return 'v' + versionMetadata.current_tag
  end

  # Returns the description of the current version.
  def version_description
    return versionMetadata.description_for_version(current_version)
  end

  # Returns true if the current version is the initial version.
  # By default "initial version" is user-centric and ignores administrative
  # version changes (for example, those run during remediations). Thus,
  # version_tags like v1.0.0 and v1.0.3 would pass the test.
  # If the :absolute option is true, the test passes only if it's truly
  # the first version.
  def is_initial_version(opts = {})
    return true if current_version == '1'
    return false if opts[:absolute]
    return version_tag =~ /\Av1\.0\./ ? true : false
  end

  # Takes a string.
  # Sets the description of the current version.
  def version_description=(val)
    versionMetadata.update_current_version(:description => val)
  end

  # Takes a string or symbol: major, minor, admin.
  # Sets the significance of the current version.
  def version_significance=(val)
    versionMetadata.update_current_version(:significance => val.to_sym)
  end

  # Returns the significance (major, minor, or admin) of the current version.
  # This method probably belongs in dor-services gem.
  def version_significance
    tags = versionMetadata.find_by_terms(:version, :tag).
           map{ |t| Dor::VersionTag.parse(t.value) }.sort
    return :major if tags.size < 2
    curr = tags[-1]
    prev = tags[-2]
    return prev.major != curr.major ? :major :
           prev.minor != curr.minor ? :minor : :admin
  end

end