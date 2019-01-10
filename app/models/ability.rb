class Ability
  include CanCan::Ability
  include Blacklight::SearchHelper

  AUTH = Hydrus::Authorizable


  attr_reader :current_user

  def initialize(user, session=nil)
    @current_user = user || Hydra::Ability.user_class.new # guest user (not logged in)

    # Read.
    can(:read, [String, ActiveFedora::Base]) do |obj|
      AUTH.can_read_object(user, get_fedora_object(obj))
    end

    can(:read, Hydrus::Collection) do |obj|
      AUTH.can_read_collection(user, obj)
    end

    can(:read, Hydrus::Item) do |obj|
      AUTH.can_read_item(user, obj)
    end

    can(:read, String) do |obj|
      o = get_fedora_object(obj)
      case o
      when Hydrus::Collection
        AUTH.can_read_collection(user, obj)
      when Hydrus::Item
        AUTH.can_read_item(user, obj)
      else
        false
      end
    end

    cannot(:read, SolrDocument)

    # Create.
    can(:create, Hydrus::Collection) if AUTH.can_create_collections(user)
    can(:create, Hydrus::Item)

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
    case obj
    when ActiveFedora::Base
      obj
    when String
      ActiveFedora::Base.find(obj, cast: true)
    else
      Rails.logger.warn "Returning #{obj} from get_fedora_object"
      obj
    end
  rescue ActiveFedora::ObjectNotFoundError
    return nil
  end
end
