module Hydrus::AccessControlsEnforcement

  # Adds various :fq paramenters to a set of SOLR search parameters.
  #   - We want only Collections or Items
  #   - And we want:
  #       - objects governed by APOs that mention the user in APO roleMD
  #       - or objects that mention the user directly in their roleMD.
  def apply_gated_discovery(solr_parameters, user_parameters)
    user = current_user || '____NOT_LOGGED_IN_USER____'
    apo_pids = Hydrus::Collection.apos_involving_user(user)
    hsq = Hydrus::SolrQueryable
    hsq.add_model_filter(solr_parameters, 'Hydrus_Collection', 'Hydrus_Item')
    hsq.add_governed_by_filter(solr_parameters, apo_pids)
    hsq.add_involved_user_filter(solr_parameters, current_user, :or => true)
    logger.debug("Solr parameters: #{ solr_parameters.inspect }")
  end

  def enforce_show_permissions *args
    # Just return if the user can read the object.
    pid = params[:id]
    return if can?(:read, pid)
    # Otherwise, redirect to the home page.
    msg  = "You do not have sufficient privileges to view the requested item."
    flash[:error] = msg
    redirect_to(root_path)
  end

  def enforce_edit_permissions *args
    # Just return if the user can edit the object.
    pid = params[:id]
    return if can?(:edit, pid)
    # Otherwise, redirect to the object's view page.
    obj  = ActiveFedora::Base.find(pid, :cast => true)
    c    = obj.hydrus_class_to_s.downcase
    msg  = "You do not have sufficient privileges to edit this #{c}."
    flash[:error] = msg
    redirect_to(polymorphic_path(obj))
  end

  def enforce_create_permissions *args
    coll_pid = params[:collection]
    if coll_pid
      # User wants to create an Item in a Collection.
      return if can?(:create_items_in, coll_pid)
      msg = "You do not have sufficient privileges to create items in this collection."
      path = polymorphic_path(Hydrus::Collection.find(coll_pid))
    else
      # User wants to create a Collection.
      return if can?(:create_collections, Hydrus::Collection)
      msg = "You do not have sufficient privileges to create new collections."
      path = root_path
    end
    flash[:error] = msg
    redirect_to(path)
  end

  # This filters out objects that you want to exclude from search results.
  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= [
      '-has_model_s:"info:fedora/afmodel:Dor_AdminPolicyObject"',
      '-has_model_s:"info:fedora/afmodel:Hydrus_AdminPolicyObject"',
    ]
  end

end
