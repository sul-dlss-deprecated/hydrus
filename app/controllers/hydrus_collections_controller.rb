class HydrusCollectionsController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  include Hydra::Controller::UploadBehavior

  before_filter :authenticate_user!
  before_filter :setup_attributes, except: [:index, :new, :list_all]
  before_filter :redirect_if_not_correct_object_type, only: [:edit, :show]

  def index
    authorize! :index, Hydrus::Collection
    flash[:warning] = 'You need to log in.'
    redirect_to new_user_session_path
  end

  def show
    authorize! :read, @fobj
  end

  def edit
    authorize! :edit, @fobj
  end

  def destroy
    authorize! :edit, @fobj
    if @fobj.is_destroyable
       @fobj.delete
       flash[:notice] = 'The collection was deleted.'
    else
      flash[:error] = 'You do not have permissions to delete this collection.'
    end
    redirect_to root_url
  end

  def discard_confirmation
    authorize! :edit, @fobj
    if @fobj.is_destroyable
      @id = params[:id]
      render 'shared/discard_confirmation'
    else
      flash[:error] = 'You do not have permissions to delete this collection.'
      redirect_to root_url
    end
  end

  def new
    authorize! :create, Hydrus::Collection
    collection = Hydrus::Collection.create(current_user)
    collection.current_user = current_user
    redirect_to edit_polymorphic_path(collection)
  end

  def update
    authorize! :edit, @fobj

    notice = []

    ####
    # Update attributes without saving.
    ####

    if params.has_key?('hydrus_collection')
      @fobj.attributes = params['hydrus_collection']
    end

    ####
    # Handle requests to add to multi-valued fields.
    ####

    has_mvf =
      params.has_key?(:add_link)


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
      flash[:error] = safe_join(errors, raw('<br />'))
      render :edit
      return
    end

    if params['should_send_role_change_emails'] == 'true' && @fobj.changed_fields.include?(:roles) # if roles have changed as the result of an update, send the appropriate emails
      @fobj.send_all_role_change_emails
    end

    ####
    # Otherwise, render the successful response.
    ####

    notice << 'Your changes have been saved.'
    flash[:notice] = safe_join(notice, raw('<br />')) unless notice.blank?

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
          render 'add_link', locals: { index: @fobj.related_item_title.length - 1 }
        else
          render json: tidy_response_from_update(@response)
        end
      }
    end

  end

  def destroy_value
    authorize! :edit, @fobj
    @fobj.descMetadata.remove_node(params[:term], params[:term_index])
    @fobj.save
    respond_to do |want|
      want.html { redirect_to :back }
      want.js
    end
  end

  def open
    authorize! :edit, @fobj
    @fobj.open
    try_to_save(@fobj, 'Collection opened')
    redirect_to(hydrus_collection_path)
  end

  def close
    authorize! :edit, @fobj
    @fobj.close
    try_to_save(@fobj, 'Collection closed')
    redirect_to(hydrus_collection_path)
  end

  def list_all
    authorize! :list_all_collections, Hydrus::Collection
    @all_collections = Hydrus::Collection.all_hydrus_collections.
                       sort.map { |p| Hydrus::Collection.find({ id: p }, lightweight: true) }
  end

  private
  def setup_attributes
    @fobj = Hydrus::Collection.find(params[:id])
    @fobj.current_user = current_user
  end
end
