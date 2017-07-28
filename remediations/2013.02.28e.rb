# frozen_string_literal: true
class Hydrus::RemediationRunner

  def remediation_2013_02_28e(opts)
    # Setup.
    unpack_args(opts, __method__)
    return unless remediation_is_needed()
    load_fedora_object()
    # Run the remediation code.
    do_remediation {
      rem_fix_prior_license
    }
  end

  # Fix an error caused by a prior remediation.
  def rem_fix_prior_license
    return unless fobj.is_item?
    log.info(__method__)
    fobj.prior_license = fobj.license
  end

end
