class HydrusItemsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  #prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => [:new, :index, :send_purl_email, :terms_of_deposit, :agree_to_terms_of_deposit]
  before_filter :check_for_collection, :only => :new
  before_filter :redirect_if_not_correct_object_type, :only => [:edit,:show,:update]

  def index
    if params.has_key?(:hydrus_collection_id)
      @document_fedora = Hydrus::Collection.find(params[:hydrus_collection_id])
      @document_fedora.current_user = current_user
    else
      flash[:warning]="You need to log in."
      redirect_to new_user_session_path
    end
  end

  def setup_attributes
    @document_fedora = Hydrus::Item.find(params[:id])
    @document_fedora.current_user = current_user
  end

  def show
  end

  def edit
  end

  def destroy
    collection=@document_fedora.collection
    if @document_fedora.is_destroyable && can?(:edit, @document_fedora)
       @document_fedora.delete
       flash[:notice]="The item was deleted."
    else
       flash[:warning]="You do not have permissions to delete this item."
     end
    redirect_to polymorphic_path([collection,:items])
  end

  def discard_confirmation
    if @document_fedora.is_destroyable && can?(:edit, @document_fedora)
      @id=params[:id]
      render 'shared/discard_confirmation'
    else
     flash[:warning]="You do not have permissions to delete this item."
     redirect_to polymorphic_path([@document_fedora.collection,:items])
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
    # Save uploaded files and their labels.
    ####

    if params.has_key?("files")
      params["files"].each do |file|
        new_file = Hydrus::ObjectFile.new
        new_file.pid = params[:id]
        new_file.label = params["file_label"][new_file.id] if params.has_key?("file_label") and params["file_label"][new_file.id]
        new_file.file = file
        new_file.save
        notice << "'#{file.original_filename}' uploaded."
        @document_fedora.files_were_changed = true  # To log an editing event.
      end
    end

    if params.has_key?("file_label")
      params["file_label"].each do |id,label|
        file = Hydrus::ObjectFile.find(id)
        unless file.label == label
          file.label = label
          file.save
          @document_fedora.files_were_changed = true  # To log an editing event.
        end
      end
    end

    ####
    # Update attributes without saving.
    ####

    if params.has_key?("hydrus_item")
      @document_fedora.attributes = params["hydrus_item"]
    end

    ####
    # Handle requests to add to multi-valued fields.
    ####

    has_mvf = (
      params.has_key?(:add_person) or
      params.has_key?(:add_link) or
      params.has_key?(:add_related_citation)
    )

    if has_mvf
      if params.has_key?(:add_person)
        @document_fedora.descMetadata.insert_person
      elsif params.has_key?(:add_link)
        @document_fedora.descMetadata.insert_related_item
      elsif params.has_key?(:add_related_citation)
        @document_fedora.descMetadata.insert_related_citation
      end
    end

    ####
    # Try to save(), and handle failure.
    ####

    unless @document_fedora.save
      errors = @document_fedora.errors.messages.map { |field, error|
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
          redirect_to [:edit, @document_fedora]
        else
          redirect_to @document_fedora
        end
      }
      want.js {
        if params.has_key?(:add_person)
          render "add_person", :locals=>{:index=>@document_fedora.person.length-1}
        elsif params.has_key?(:add_link)
          render "add_link", :locals=>{:index=>@document_fedora.related_item_title.length-1}
        elsif params.has_key?(:add_related_citation)
          render "add_related_citation", :locals=>{:index=>@document_fedora.related_citation.length-1}
        else
          render :json => tidy_response_from_update(@response)
        end
      }
    end

  end

  def terms_of_deposit
    @pid=params[:pid]
    @from=params[:from]
    @document_fedora=Hydrus::Item.find(@pid)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def agree_to_terms_of_deposit
    @pid=params[:pid]
    @from=params[:from]
    @document_fedora=Hydrus::Item.find(@pid)
    @document_fedora.accept_terms_of_deposit(current_user.to_s)
    @document_fedora.save
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def send_purl_email
    @pid=params[:pid]
    @from=params[:from]
    @document_fedora=Hydrus::Item.find(@pid)
    @recipients=params[:recipients]
    HydrusMailer.send_purl(:recipients=>@recipients,:current_user=>current_user,:object=>@document_fedora).deliver unless @recipients.blank? 
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def destroy_value
    @document_fedora.descMetadata.remove_node(params[:term], params[:term_index])
    @document_fedora.save
    respond_to do |want|
      want.html {redirect_to :back}
      want.js
    end
  end

  def publish_directly
    @document_fedora.cannot_do(:publish_directly) unless can?(:edit, @document_fedora)
    @document_fedora.publish_directly
    try_to_save(@document_fedora, "Item published.")
    redirect_to(hydrus_item_path)
  end

  def submit_for_approval
    @document_fedora.cannot_do(:submit_for_approval) unless can?(:edit, @document_fedora)
    @document_fedora.submit_for_approval
    try_to_save(@document_fedora, "Item submitted for approval.")
    redirect_to(hydrus_item_path)
  end

  def approve
    @document_fedora.cannot_do(:approve) unless can?(:review, @document_fedora)
    @document_fedora.approve
    try_to_save(@document_fedora, "Item approved and published.")
    redirect_to(hydrus_item_path)
  end

  def disapprove
    @document_fedora.cannot_do(:disapprove) unless can?(:review, @document_fedora)
    @document_fedora.disapprove(params['hydrus_item_disapproval_reason'])
    try_to_save(@document_fedora, "Item returned.")
    redirect_to(hydrus_item_path)
  end

  def resubmit
    @document_fedora.cannot_do(:resubmit) unless can?(:edit, @document_fedora)
    @document_fedora.resubmit
    try_to_save(@document_fedora, "Item resubmitted for approval.")
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
