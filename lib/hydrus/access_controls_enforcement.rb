module Hydrus::AccessControlsEnforcement

  def apply_gated_discovery solr_parameters, user_parameters
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
      return if can?(:create, Hydrus::Collection)
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
