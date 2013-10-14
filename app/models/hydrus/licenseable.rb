module Hydrus::Licenseable
  extend ActiveSupport::Concern

  # Return's true if the Item belongs to a collection that allows
  # Items to set their own licenses.
  def licenses_can_vary
    return false unless respond_to? :collection
    return collection.license_option == 'varies'
  end

  # Returns the text label of the object's license.
  def license_text
    nds = rightsMetadata.use.human.nodeset
    nd  = nds.find { |nd| nd[:type] != 'useAndReproduction' }
    return nd ? nd.content : ''
  end

  # Returns the license group code (eg creativeCommons) corresponding
  # to the object's license.
  def license_group_code
    return rightsMetadata.use.machine.type.first
  end

  # Returns the object's license code: cc-by, pddl...
  # Returns license code of 'none' if there is no license, a
  # behavior that parallels the setter.
  #
  # Note: throughout the Hydrus app, creativeCommons license codes
  # have a cc- prefix, which disambiguates those code from similar
  # openDataCommons licenses; however, in the rightsMetadata XML
  # the creativeCommons codes lack the cc- prefix. That's why the
  # license getter and setter add and remove those prefixes.
  def license
    nd = rightsMetadata.use.machine.nodeset.first
    return 'none' unless nd
    prefix = nd[:type] == 'creativeCommons' ? 'cc-' : ''
    return prefix + nd.text
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Replaces the existing license, if any, with the license for that code.
  def license=(code)
    license_will_change!
    rightsMetadata.remove_license
    return if code == 'none'
    gcode = Hydrus.license_group_code(code)
    txt   = Hydrus.license_human(code)
    code  = code.sub(/\Acc-/, '') if gcode == 'creativeCommons'
    rightsMetadata.insert_license(gcode, code, txt)
  end

  def license_changed?
    @license_changed == true
  end

  def license_will_change!
    @license_changed = true
  end
end