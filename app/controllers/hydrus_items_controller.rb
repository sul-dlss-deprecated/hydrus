class HydrusItemsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  #prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => [:new, :index, :send_purl_email, :terms_of_deposit, :agree_to_terms_of_deposit]
  before_filter :check_for_collection, :only => :new
  before_filter :redirect_if_not_correct_object_type, :only => [:edit,:show]

  def index
    if params.has_key?(:hydrus_collection_id)
      @fobj = Hydrus::Collection.find(params[:hydrus_collection_id])
      @fobj.current_user = current_user
    else
      flash[:warning]="You need to log in."
      redirect_to new_user_session_path
    end
  end

  def setup_attributes
    @fobj = Hydrus::Item.find(params[:id])
    @fobj.current_user = current_user
  end

  def show
  end

  def edit
  end

  def destroy
    collection=@fobj.collection
    if @fobj.is_destroyable && can?(:edit, @fobj)
       @fobj.delete
       flash[:notice]="The item was deleted."
    else
       flash[:error]="You do not have permissions to delete this item."
     end
    redirect_to polymorphic_path([collection,:items])
  end

  def discard_confirmation
    if @fobj.is_destroyable && can?(:edit, @fobj)
      @id=params[:id]
      render 'shared/discard_confirmation'
    else
     flash[:error]="You do not have permissions to delete this item."
     redirect_to polymorphic_path([@fobj.collection,:items])
    end
  end

  def new
    coll_pid = params[:collection]
    item = Hydrus::Item.create(coll_pid, current_user)
    item.current_user = current_user
    redirect_to edit_polymorphic_path(item)
  end

  def update

    notice = []

    ####
    # Save uploaded files, along with their info (label and hide status).
    ####

    file_info = params["file_info"] || {}

    if params.has_key?("files")
      params["files"].each do |upload_file|
        hof = Hydrus::ObjectFile.new
        hof.pid = params[:id]
        hof.set_file_info(file_info[hof.id])
        hof.file = upload_file
        hof.save
        notice << "'#{upload_file.original_filename}' uploaded."
        @fobj.files_were_changed = true  # To log an editing event.
      end
    end

    file_info.each do |id, h|
      hof = Hydrus::ObjectFile.find(id)
      if hof.set_file_info(h)
        hof.save
        @fobj.files_were_changed = true  # To log an editing event.
      end
    end

    ####
    # Update attributes without saving.
    ####

    if params.has_key?("hydrus_item")
      @fobj.attributes = params["hydrus_item"]
    end

    ####
    # Handle requests to add to multi-valued fields.
    ####

    has_mvf = (
      params.has_key?(:add_contributor) or
      params.has_key?(:add_link) or
      params.has_key?(:add_related_citation)
    )

    if has_mvf
      if params.has_key?(:add_contributor)
        @fobj.insert_contributor('', @fobj.class.default_contributor_role)
      elsif params.has_key?(:add_link)
        @fobj.descMetadata.insert_related_item
      elsif params.has_key?(:add_related_citation)
        @fobj.descMetadata.insert_related_citation
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
        if params.has_key?(:add_contributor)
          i = @fobj.person.length - 1
          render "add_contributor", :locals => { :index => i }
        elsif params.has_key?(:add_link)
          i = @fobj.related_items.length - 1
          render "add_link", :locals => { :index => i }
        elsif params.has_key?(:add_related_citation)
          i = @fobj.related_citation.length - 1
          render "add_related_citation", :locals => { :index => i }
        else
          render :json => tidy_response_from_update(@response)
        end
      }
    end

  end

  def terms_of_deposit
    @pid=params[:pid]
    @from=params[:from]
    @fobj=Hydrus::Item.find(@pid)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def agree_to_terms_of_deposit
    @pid=params[:pid]
    @from=params[:from]
    @fobj=Hydrus::Item.find(@pid)
    @fobj.accept_terms_of_deposit(current_user)
    @fobj.save
    respond_to do |format|
      format.html
      format.js
    end
  end

  def send_purl_email
    @pid=params[:pid]
    @from=params[:from]
    @fobj=Hydrus::Item.find(@pid)
    @recipients=params[:recipients]
    HydrusMailer.send_purl(:recipients=>@recipients,:current_user=>current_user,:object=>@fobj).deliver unless @recipients.blank?
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create_file
    # Binary Base64 files from drag-and-drop.
    if params.has_key?("binary_data")
      binary_file = params["binary_data"].gsub(/^.*;base64,/, "")
      temp_file = StringIO.new(Base64.decode64(binary_file))
      temp_file.class_eval { attr_accessor :original_filename }
      temp_file.original_filename = params["file_name"]
      new_file = Hydrus::ObjectFile.new
      new_file.pid = params[:id]
      new_file.file = temp_file
      new_file.save
      @file = new_file
    end
  end

  def destroy_file
    @file_id = params[:file_id]
    hof = Hydrus::ObjectFile.find(@file_id)
    hof.destroy
    respond_to do |want|
       want.html {
         flash[:warning] = "The file was deleted"
         redirect_to :back
       }
       want.js {
         render :action => :destroy_file
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

  def publish_directly
    @fobj.cannot_do(:publish_directly) unless can?(:edit, @fobj)
    @fobj.publish_directly
    try_to_save(@fobj, "Item published: #{@fobj.version_tag()}.")
    redirect_to(hydrus_item_path)
  end

  def submit_for_approval
    @fobj.cannot_do(:submit_for_approval) unless can?(:edit, @fobj)
    @fobj.submit_for_approval
    try_to_save(@fobj, "Item submitted for approval.")
    redirect_to(hydrus_item_path)
  end

  def approve
    @fobj.cannot_do(:approve) unless can?(:review, @fobj)
    @fobj.approve
    try_to_save(@fobj, "Item approved and published: #{@fobj.version_tag()}.")
    redirect_to(hydrus_item_path)
  end

  def disapprove
    @fobj.cannot_do(:disapprove) unless can?(:review, @fobj)
    @fobj.disapprove(params['hydrus_item_disapproval_reason'])
    try_to_save(@fobj, "Item returned.")
    redirect_to(hydrus_item_path)
  end

  def resubmit
    @fobj.cannot_do(:resubmit) unless can?(:edit, @fobj)
    @fobj.resubmit
    try_to_save(@fobj, "Item resubmitted for approval.")
    redirect_to(hydrus_item_path)
  end

  def open_new_version
    @fobj.cannot_do(:open_new_version) unless can?(:edit, @fobj)
    @fobj.open_new_version
    try_to_save(@fobj, "New version opened.")
    redirect_to(hydrus_item_path)
  end

  protected

  def enforce_index_permissions
    if params.has_key?(:hydrus_collection_id)
      unless can? :read, params[:hydrus_collection_id]
        flash[:error] = "You do not have permissions to view this collection."
        redirect_to root_path
      end
    end
  end

  def check_for_collection
    unless params.has_key?(:collection)
      flash[:error] = "You cannot create an item without specifying a collection."
      redirect_to root_path
    end
  end

end
