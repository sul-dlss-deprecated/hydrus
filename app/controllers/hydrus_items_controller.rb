class HydrusItemsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  #prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => :new
  before_filter :check_for_collection, :only => :new
  before_filter :redirect_if_not_correct_object_type, :only => [:edit,:show,:update]

  def index
    flash[:warning]="You need to log in."
    redirect_to new_user_session_path
  end

  def setup_attributes
    @document_fedora = Hydrus::Item.find(params[:id])
    @document_fedora.current_user = current_user
  end

  def show
  end

  def edit
  end

  def new
    item = Hydrus::Item.create(params[:collection], current_user)
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
    # Save the object and keep track of its success/failure.
    ####

    save_ok = true
    if params.has_key?("hydrus_item")
      save_ok = save_ok && @document_fedora.update_attributes(params["hydrus_item"])
      # Unset @files_were_changed to prevent repeated editing events for :files.
      # That can occur when the object is saved twice, which occurs when:
      #   (a) Javascript is disabled
      #   (b) User edts some fields -- hence update_attributes() ran above.
      #   (b) User asks to add another multi-valued field -- hence save() runs below.
      @document_fedora.files_were_changed = nil
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
      # Add the new field.
      if params.has_key?(:add_person)
        @document_fedora.descMetadata.insert_person
      elsif params.has_key?(:add_link)
        @document_fedora.descMetadata.insert_related_item
      elsif params.has_key?(:add_related_citation)
        @document_fedora.descMetadata.insert_related_citation
      end
      # Save the object and update our success/failure indicator.
      save_ok = save_ok && @document_fedora.save
    end

    ####
    # Handle failure of update_attributes() or save().
    ####

    unless save_ok
      errors = []
      @document_fedora.errors.messages.each do |field, error|
        errors << "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
      end
      flash[:error] = errors.join("<br/>").html_safe
      render :edit and return
    end

    ####
    # Otherwise, render the successful response.
    ####

    notice << "Your changes have been saved."
    flash[:notice] = notice.join("<br/>").html_safe unless notice.blank?

    respond_to do |want|
      want.html {
        if has_mvf
          # if we want to pass on parameters to edit screen we'll need to use the named route
          # redirect_to edit_polymorphic_path(@document_fedora, :my_param=>"oh-hai-there")
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

  def destroy_value
    @document_fedora.descMetadata.remove_node(params[:term], params[:term_index])
    @document_fedora.save
    respond_to do |want|
      want.html {redirect_to :back}
      want.js
    end
  end

  protected

  def check_for_collection
    unless params.has_key?(:collection)
      flash[:error] = "You cannot create an item without specifying a collection."
      redirect_to root_path
    end
  end

end
