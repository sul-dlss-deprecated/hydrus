# frozen_string_literal: true
module Hydrus::AccessControlsEnforcement

  # Redirects to home page with a flash error if user lacks
  # authorization to read the Item/Collection.
  def enforce_show_permissions *args
    # Just return if the user can read the object.
    obj=@fobj ? @fobj : params[:id]
    pid=params[:id]

    return if can?(:read, obj)
    # Otherwise, redirect to the home page.
    msg  = "You do not have sufficient privileges to view the requested item: '#{pid}'."
    msg = "Please sign in below and you will be directed to the requested item: '#{pid}'." unless current_user
    flash[:error] = msg
    redirect_to_correct_page(root_path)
  end

  def redirect_to_correct_page(url)
    request_url = request.fullpath # try to get the path the user is currently only before redirecting them
    request_url = root_url if (request_url.blank? || request_url==new_user_session_path || request_url==new_user_session_path) # force the redirect page to be the home page if no return page found or the return page is the login page
    session['user_return_to']=request_url
    current_user.nil? ? redirect_to(new_user_session_path(referrer: request_url)) : redirect_to(url)
  end

  # Redirects to the Item/Collection view page with a flash error
  # if user lacks authorization to edit the Item/Collection.
  def enforce_edit_permissions *args
    # Just return if the user can edit the object.
    obj=@fobj ? @fobj : params[:id]
    pid=params[:id]
    return if can?(:edit, obj)
      # Otherwise, redirect to the home page.
      msg  = "You do not have sufficient privileges to edit the requested item: '#{pid}'."
      flash[:error] = msg
      redirect_to_correct_page(root_path)
    end

    # Handles two cases:
    # (1) Create new Item in a given Collection.
    #     Redirects to the home page with a flash error
    #     if user lacks authorization to create Items in the Collection.
    # (2) Create new Collections.
    #     Redirects to the home page with a flash error if the user
    #     lacks authorization to create new Collections.
    def enforce_create_permissions *args
      coll_pid = params[:collection]
      if coll_pid
        # User wants to create an Item in a Collection.
        return if can?(:create_items_in, coll_pid)
        msg = "to create items in this collection: '#{coll_pid}'"
      else
        # User wants to create a Collection.
        return if can?(:create_collections, Hydrus::Collection)
        msg = 'to create new collections'
      end
      flash[:error] = "You do not have sufficient privileges #{msg}."
      redirect_to_correct_page(root_path)
    end

    # Adds some :fq paramenters to a set of SOLR search parameters
    # so that search results contains only those Items/Collections
    # the user is authorized to see.
    def apply_gated_discovery(solr_parameters, user_parameters)
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
      logger.debug("Solr parameters: #{ solr_parameters.inspect }")
    end

  end
