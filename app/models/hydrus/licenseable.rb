module Hydrus::Licenseable
  # Returns the text label of the object's license.
  def license_text
    nds = rightsMetadata.use.human.nodeset
    nd  = nds.find { |nd| nd[:type] != 'useAndReproduction' }
    nd ? nd.content : ''
  end

  # Returns the license group code (eg creativeCommons) corresponding
  # to the object's license.
  def license_group_code
    rightsMetadata.use.machine.type.first
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
    prefix + nd.text
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Replaces the existing license, if any, with the license for that code.
  def license=(code)
    rightsMetadata.remove_license
    return if code == 'none'
    hgo   = Hydrus::GenericObject
    gcode = hgo.license_group_code(code)
    txt   = hgo.license_human(code)
    code  = code.sub(/\Acc-/, '') if gcode == 'creativeCommons'
    rightsMetadata.insert_license(gcode, code, txt)
  end
end