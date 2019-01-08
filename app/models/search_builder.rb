class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # Add a filter query to restrict the search to documents the current user has access to
  include Hydra::AccessControlsEnforcement
  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_access_controls_to_solr_params]

  private

  # Adds some :fq paramenters to a set of SOLR search parameters
  # so that search results contains only those Items/Collections
  # the user is authorized to see.
  def apply_gated_discovery(solr_parameters)
    # Get the PIDs of APOs that include the user in their roleMD.
    apo_pids = Hydrus::Collection.apos_involving_user(current_user)
    # The search search should find:
    #      objects governed by APOs that mention current user in the APO roleMD
    #   OR objects that mention the user directly in their roleMD
    hsq = Hydrus::SolrQueryable
    hsq.add_gated_discovery(solr_parameters, apo_pids, current_user)
    # In addition, the objects must be Hydrus Collections or Items (not APOs).
    hsq.add_model_filter(solr_parameters, 'Hydrus_Collection', 'Hydrus_Item')
    # If there is no user, add a condition to guarantee zero search results.
    # The enforce_index_permissions() method in the catalog controller also
    # guards against this scenario, but this provides extra insurance.
    unless current_user
      bogus_model = '____USER_IS_NOT_LOGGED_IN____'
      hsq.add_model_filter(solr_parameters, bogus_model)
    end
    # Logging.
    logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  delegate :current_user, to: :current_ability
  delegate :logger, to: Rails
end
