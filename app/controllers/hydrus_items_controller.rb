class HydrusItemsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::Controller::UploadBehavior

  before_filter :authenticate_user!
  before_filter :setup_attributes, except: [:new, :index, :send_purl_email, :terms_of_deposit, :agree_to_terms_of_deposit]
  before_filter :check_for_collection, only: :new
  before_filter :redirect_if_not_correct_object_type, only: [:edit,:show]

  def index
    unless params.has_key?(:hydrus_collection_id)
      raise ActionController::RoutingError.new('Not Found')
    end

    @fobj = Hydrus::Collection.find(params[:hydrus_collection_id])
    @fobj.current_user = current_user
    authorize! :read, @fobj
    @items = @fobj.items_list(num_files: true)
  end

  def setup_attributes
    @fobj = Hydrus::Item.find(params[:id])
    @fobj.current_user = current_user
  end

  def show
    authorize! :read, @fobj
  end

  def edit
    authorize! :edit, @fobj
  end

  def destroy
    authorize! :edit, @fobj
    collection = @fobj.collection
    if @fobj.is_destroyable
      @fobj.delete
      flash[:notice] = 'The item was deleted.'
    else
      flash[:error] = 'You do not have permissions to delete this item.'
    end
    redirect_to polymorphic_path([collection,:items])
  end

  def discard_confirmation
    authorize! :edit, @fobj
    if @fobj.is_destroyable
      @id = params[:id]
      render 'shared/discard_confirmation'
    else
      flash[:error] = 'You do not have permissions to delete this item.'
      redirect_to polymorphic_path([@fobj.collection,:items])
    end
  end

  def new
    coll_pid = params[:collection]

    authorize! :create, Hydrus::Item
    authorize! :create_items_in, coll_pid

    item_type = params[:type] || Hydrus::Application.config.default_item_type
    item = ItemService.create(coll_pid, current_user, item_type)
    item.current_user = current_user
    redirect_to edit_polymorphic_path(item)
  end

  def update

    authorize! :edit, @fobj
    notice = []

    ####
    # Save uploaded files, along with their info (label and hide status).
    ####

    file_info = params['file_info'] || {}
    flash[:error] = ''

    if params.has_key?('files')
      params['files'].each do |upload_file|
        hof = Hydrus::ObjectFile.new
        hof.pid = params[:id]
        hof.set_file_info(file_info[hof.id])
        hof.file = upload_file
        hof.save
        hof.remove_dupes
        notice << "'#{upload_file.original_filename}' uploaded."
        @fobj.files_were_changed = true  # To log an editing event.
      end
    end

    file_info.each do |id, h|
      hof = Hydrus::ObjectFile.find_by_id(id)
      if hof && hof.set_file_info(h)
        hof.save
        hof.remove_dupes
        @fobj.files_were_changed = true  # To log an editing event.
      end
    end

    ####
    # Update attributes without saving.
    ####

    if params.has_key?('hydrus_item')
      @fobj.attributes = params['hydrus_item']
    end

    ####
    # Handle requests to add to multi-valued fields.
    ####

    has_mvf = (
    params.has_key?(:add_contributor) ||
    params.has_key?(:add_link) ||
    params.has_key?(:add_related_citation)
    )

    if has_mvf
      if params.has_key?(:add_contributor)
        @fobj.insert_contributor
      elsif params.has_key?(:add_link)
        @fobj.descMetadata.insert_related_item
      elsif params.has_key?(:add_related_citation)
        @fobj.descMetadata.insert_related_citation
      end
    end

    ####
    # Try to save(), and handle failure.
    ####

    # delete any files that are missing and warn the user
    if @fobj.delete_missing_files > 0
      flash[:error] += 'Some files did not upload correctly. Please check and re-upload any missing files.'
    end

    unless @fobj.save
      errors = @fobj.errors.messages.map { |field, error|
        "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
      }
      flash[:error] += safe_join(errors, raw('<br />'))
      render :edit
      return
    end

    ####
    # Otherwise, render the successful response.
    ####

    notice << 'Your changes have been saved.'
    @fobj.validate!
    notice << @fobj.errors.messages.map { |field, error|
        "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
      }
    flash[:notice] = safe_join(notice, raw('<br />')) unless notice.blank?
    flash[:error] = nil if flash[:error].blank?

    respond_to do |want|
      want.html {
        if has_mvf
          redirect_to [:edit, @fobj]
        else
          redirect_to @fobj
        end
      }
      want.js {
        if params.has_key?(:add_contributor)
          i = @fobj.contributors.length - 1
          render 'add_contributor', locals: { index: i, guid: SecureRandom.uuid }
        elsif params.has_key?(:add_link)
          i = @fobj.related_items.length - 1
          render 'add_link', locals: { index: i, guid: SecureRandom.uuid  }
        elsif params.has_key?(:add_related_citation)
          i = @fobj.related_citation.length - 1
          render 'add_related_citation', locals: { index: i, guid: SecureRandom.uuid  }
        else
          render json: tidy_response_from_update(@response)
        end
      }
    end

  end

  def terms_of_deposit
    @pid = params[:pid]
    @from = params[:from]
    @fobj = Hydrus::Item.find(@pid)
    authorize! :read, @fobj
    respond_to do |format|
      format.html
      format.js
    end
  end

  def agree_to_terms_of_deposit
    @pid = params[:pid]
    @from = params[:from]
    @fobj = Hydrus::Item.find(@pid)
    authorize! :edit, @fobj
    @fobj.accept_terms_of_deposit(current_user)
    @fobj.save
    respond_to do |format|
      format.html
      format.js
    end
  end

  def send_purl_email
    @pid = params[:pid]
    @from = params[:from]
    @fobj = Hydrus::Item.find(@pid)
    authorize! :read, @fobj
    @recipients = params[:recipients]
    HydrusMailer.send_purl(recipients: @recipients,current_user: current_user,object: @fobj).deliver unless @recipients.blank?
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create_file
    authorize! :edit, @fobj
    if request.post?
      @file = Hydrus::ObjectFile.new
      @file.pid = params[:id]
      @file.file = params[:file]
      @file.save
      @dupe_ids = @file.dupes.collect { |dupe| dupe.id }
      @file.remove_dupes
    else
      render nothing: true
      return
    end
  end

  def destroy_file
    authorize! :edit, @fobj
    @file_id = params[:file_id]
    hof = Hydrus::ObjectFile.find_by_id(@file_id)
    hof.destroy if hof
    respond_to do |want|
      want.html {
        flash[:warning] = 'The file was deleted.'
        redirect_to :back
      }
      want.js {
        render action: :destroy_file
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

  def publish_directly
    authorize! :edit, @fobj
    @fobj.publish_directly
    try_to_save(@fobj, "Item published: #{@fobj.version_tag()}.")
    redirect_to(hydrus_item_path)
  end

  def submit_for_approval
    authorize! :edit, @fobj
    @fobj.submit_for_approval
    try_to_save(@fobj, 'Item submitted for approval.')
    redirect_to(hydrus_item_path)
  end

  def approve
    authorize! :review, @fobj
    @fobj.approve
    try_to_save(@fobj, "Item approved and published: #{@fobj.version_tag()}.")
    redirect_to(hydrus_item_path)
  end

  def disapprove
    authorize! :review, @fobj
    @fobj.disapprove(params['hydrus_item_disapproval_reason'])
    try_to_save(@fobj, 'Item returned.')
    redirect_to(hydrus_item_path)
  end

  def resubmit
    authorize! :edit, @fobj
    @fobj.resubmit
    try_to_save(@fobj, 'Item resubmitted for approval.')
    redirect_to(hydrus_item_path)
  end

  def open_new_version
    authorize! :edit, @fobj
    @fobj.open_new_version
    try_to_save(@fobj, 'New version opened.')
    redirect_to(hydrus_item_path)
  end

  protected


  def check_for_collection
    unless params.has_key?(:collection)
      flash[:error] = 'You cannot create an item without specifying a collection.'
      redirect_to root_path
    end
  end

end
