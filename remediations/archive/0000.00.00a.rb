class Hydrus::RemediationRunner

  def remediation_0000_00_00a(opts)

    # Setup.
    unpack_args(opts, __method__)
    return unless remediation_is_needed()
    load_fedora_object()

    # Run the steps of the remediation.
    do_remediation {
      rem_foo
      rem_bar
    }

  end

  # Implements the FOO fix.
  def rem_foo
    # Bail if pre-conditions are not satisfied.
    return if ...

    # Log that we are starting this step of the remdiation.
    log.info(__method__)

    # Do stuff.
    #  - Use fobj to reference the Fedora object.
    #  - Typically there is no need to open a version or save the object;
    #    that is handled by the do_remediation method.
    #  - If you manipulate datastreams at the low level (for example, using
    #    Nokogiri and bypassing OM), be sure to call content_will_change!
    #    on the datastream.
    ...

  end

  # Follow the same pattern.
  def rem_bar
    ...
  end

end
