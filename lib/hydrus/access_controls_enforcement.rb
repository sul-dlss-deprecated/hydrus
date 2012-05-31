module Hydrus::AccessControlsEnforcement
  # XXX Disable solr gated discovery for this iteration
  def apply_gated_discovery solr_parameters, user_parameters

  end

  # This filters out objects that you want to exclude from search results.
  # By default it only excludes FileAssets
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= [
      '-has_model_s:"info:fedora/afmodel:Dor_AdminPolicyObject"',
    ]
  end

end
