class Hydrus::RemediationRunner

  # Used with these deployments:
  #   production: 2013.02.28b
  def remediation_2013_02_27a(opts)
    # Setup.
    unpack_args(opts, __method__)
    return unless remediation_is_needed()
    load_fedora_object()
    # Run the remediation code.
    do_remediation {
      rem_add_object_version
      rem_add_prior_vis_and_license
      rem_remove_cc_prefix
      rem_modify_publish_nodes
      rem_remove_access_edit_nodes
      rem_refresh_dublin_core_of_apos
    }
  end

  # Adds object_version to hydrusProperties.
  def rem_add_object_version
    log.info(__method__)
    fobj.object_version = remed_version
  end

  # Sets a value for prior_visibility for Items.
  def rem_add_prior_vis_and_license
    return unless fobj.is_item?
    log.info(__method__)
    fobj.prior_visibility = 'stanford'   if fobj.prior_visibility.nil?
    fobj.prior_license    = fobj.license if fobj.prior_license.nil?
  end

  # Modify <use> section in rightsMetadata: remove cc- prefixes
  # from creativeCommons licenses. For example:
  #  OLD: <machine type="creativeCommons">cc-by</machine>
  #  NEW: <machine type="creativeCommons">by</machine>
  def rem_remove_cc_prefix
    return if fobj.is_apo?
    log.info(__method__)
    nd = fobj.rightsMetadata.use.machine.nodeset.first
    if nd && nd[:type] == 'creativeCommons'
      nd.content = nd.content.gsub(/\Acc-/, '')
      fobj.rightsMetadata.content_will_change!
      if fobj.is_item? && !fobj.is_initial_version
        fobj.prior_license = fobj.license
        fobj.hydrusProperties.content_will_change!
      end
    end
  end

  # Change publish attribute names in hydrusProperties.
  # For published Items and Collections:
  #   - copy publishTime to these new nodes:
  #       submittedForPublishTime
  #       initialSubmittedForPublishTime
  #   - delete publishTime node
  # For Items in subsequent versions:
  #   - creted an initialPublishTime node
  def rem_modify_publish_nodes
    return if fobj.is_apo?
    return unless fobj.is_published
    log.info(__method__)
    # Copy publishTime content to two new nodes,
    # and delete the publishTime node.
    hp = fobj.hydrusProperties.ng_xml
    txt = ''
    old_node = hp.at_xpath('//publishTime')
    if old_node
      txt = old_node.content
      ['submittedForPublishTime', 'initialSubmittedForPublishTime'].each do |node_name|
        nd = Nokogiri::XML::Node.new(node_name, hp)
        nd.content = txt
        hp.root.add_child(nd)
      end
      old_node.remove
    else
      log_warning('did not find publishTime node')
    end
    # For Items beyond first version, add an initialPublishTime node.
    return if fobj.is_collection? || fobj.is_initial_version
    node_name = 'initialPublishTime'
    unless hp.at_xpath('//' + node_name)
      new_node = Nokogiri::XML::Node.new(node_name, hp)
      new_node.content = txt
      hp.root.add_child(new_node)
    end
    # Mark hydrusProperties as dirty.
    fobj.hydrusProperties.content_will_change!
  end

  # Remove <access type="edit"> nodes from rightsMetadata, for Items and Collections.
  def rem_remove_access_edit_nodes
    return if fobj.is_apo?
    log.info(__method__)
    nodes = fobj.rightsMetadata.access.nodeset
    nodes.each do |nd|
      if nd[:type] == 'edit'
        nd.remove
        fobj.rightsMetadata.content_will_change!
      end
    end
  end

  # Refresh the dublin core datastream of APOs.
  def rem_refresh_dublin_core_of_apos
    return unless fobj.is_apo?
    log.info(__method__)
    fobj.dc.content = fobj.generate_dublin_core.to_s
    fobj.dc.content_will_change!
  end

end
