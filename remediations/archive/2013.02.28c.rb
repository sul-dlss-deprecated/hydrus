class Hydrus::RemediationRunner
  # Run solely for the purpose of opening-closing a version for Items.
  def remediation_2013_02_28c(opts)
    # Setup.
    unpack_args(opts, __method__)
    return unless remediation_is_needed()
    load_fedora_object()
    # Run the remediation code.
    do_remediation {
      # Nothing to do here. Just want the following to happen:
      #   - update value of object_version for everything
      #   - open new version and close it for Items
    }
  end
end
