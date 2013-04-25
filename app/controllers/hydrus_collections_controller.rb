class HydrusCollectionsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => [:index, :new, :list_all]
  before_filter :redirect_if_not_correct_object_type, :only => [:edit, :show]

  def index
    flash[:warning]="You need to log in."
    redirect_to new_user_session_path
  end

  def setup_attributes
    @fobj = Hydrus::Collection.find(params[:id])
    @fobj.current_user = current_user
  end

  def show
  end

  def edit
  end

  def destroy
    if @fobj.is_destroyable && can?(:edit, @fobj)
       @fobj.delete
       flash[:notice]="The collection was deleted."
    else
      flash[:error]="You do not have permissions to delete this collection."
    end
    redirect_to root_url
  end

  def discard_confirmation
    if @fobj.is_destroyable && can?(:edit, @fobj)
      @id=params[:id]
      render 'shared/discard_confirmation'
    else
      flash[:error]="You do not have permissions to delete this collection."
      redirect_to root_url
    end
  end

  def new
    collection = Hydrus::Collection.create(current_user)
    collection.current_user = current_user
    redirect_to edit_polymorphic_path(collection)
  end

  def update

    notice = []

    depositors_before_update = @fobj.apo.persons_with_role("hydrus-collection-item-depositor")

    ####
    # Update attributes without saving.
    ####

    if params.has_key?("hydrus_collection")
      @fobj.attributes = params["hydrus_collection"]
    end

    if @fobj.is_open
      depositors_after_update = @fobj.apo.persons_with_role("hydrus-collection-item-depositor")
      new_depositors = (depositors_after_update - depositors_before_update).to_a.join(", ")
      @fobj.send_invitation_email_notification(new_depositors)
    end

    ####
    # Handle requests to add to multi-valued fields.
    ####

    has_mvf = (
      params.has_key?(:add_link)
    )

    if has_mvf
      if params.has_key?(:add_link)
        @fobj.descMetadata.insert_related_item
      end
    end

    ####
    # Try to save(), and handle failure.
    ####

    unless @fobj.save
      errors = @fobj.errors.messages.map { |field, error|
        "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
      }
      flash[:error] = errors.join("<br/>").html_safe
      render :edit
      return
    end

    ####
    # Otherwise, render the successful response.
    ####

    notice << "Your changes have been saved."
    flash[:notice] = notice.join("<br/>").html_safe unless notice.blank?

    respond_to do |want|
      want.html {
        if has_mvf
          redirect_to [:edit, @fobj]
        else
          redirect_to @fobj
        end
      }
      want.js {
        if params.has_key?(:add_link)
          render "add_link", :locals=>{:index=>@fobj.related_item_title.length-1}
        else
          render :json => tidy_response_from_update(@response)
        end
      }
    end

  end

  def destroy_value
    @fobj.descMetadata.remove_node(params[:term], params[:term_index])
    @fobj.save
    respond_to do |want|
      want.html {redirect_to :back}
      want.js
    end
  end

  def open
    @fobj.cannot_do(:open) unless can?(:edit, @fobj)
    @fobj.open
    try_to_save(@fobj, "Collection opened")
    redirect_to(hydrus_collection_path)
  end

  def close
    @fobj.cannot_do(:close) unless can?(:edit, @fobj)
    @fobj.close
    try_to_save(@fobj, "Collection closed")
    redirect_to(hydrus_collection_path)
  end

  def list_all
    unless can?(:list_all_collections, nil)
      flash[:error] = "You do not have permissions to list all collections."
      redirect_to root_url
    end
    @all_collections = Hydrus::Collection.all_hydrus_collections.
                       sort.map { |p| Hydrus::Collection.find(p, :lightweight => true) }
  end

end
