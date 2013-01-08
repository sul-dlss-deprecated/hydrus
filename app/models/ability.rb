class Ability

  include CanCan::Ability
  include Hydra::Ability

  AUTH = Hydrus::Authorizable

  def hydra_default_permissions(user, session, *args)

    # Read.

    can(:read, [String, ActiveFedora::Base]) do |obj|
      AUTH.can_read_object(user, get_fedora_object(obj))
    end

    cannot(:read, SolrDocument)

    # Create.

    can(:create_collections, :all) if AUTH.can_create_collections(user)

    can(:create_items_in, [String, Hydrus::Collection]) do |obj|
      AUTH.can_create_items_in(user, get_fedora_object(obj))
    end

    # Update/edit.

    can([:edit, :update], [String, ActiveFedora::Base]) do |obj|
      AUTH.can_edit_object(user, get_fedora_object(obj))
    end

    cannot([:edit, :update], SolrDocument)

    # Review (approve/disapprove).

    can(:review, [String, ActiveFedora::Base]) do |obj|
      AUTH.can_review_item(user, get_fedora_object(obj))
    end

    # Admin actions:
    #   - View datastreams.
    #   - List all collections.

    can(:view_datastreams,     :all) if AUTH.can_act_as_administrator(user)
    can(:list_all_collections, :all) if AUTH.can_act_as_administrator(user)

    # Destroy.

    cannot(:destroy, String)
    cannot(:destroy, ActiveFedora::Base)
    cannot(:destroy, SolrDocument)

  end

  # Takes a String (presumably a pid) or an ActiveFedora object.
  # Returns the corresponding ActiveFedora object, if it exists; nil otherwise.
  # 
  # Note: We catch the exception below to handle the scenario of a user manually
  # typing a URL with an invalid druid. In that case, this method will
  # return nil, and our methods in authorizable.rb need to return false
  # when the given a nil item/collection.
  def get_fedora_object(obj)
    # If already an ActiveFedora object, just return it.
    return obj unless obj.kind_of?(String)
    # Use the PID to find the object.
    begin
      return ActiveFedora::Base.find(obj, :cast => true)
    rescue ActiveFedora::ObjectNotFoundError
      return nil
    end
  end

end
