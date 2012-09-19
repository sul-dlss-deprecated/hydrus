class HydrusCollectionsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => :new
  before_filter :redirect_if_not_correct_object_type, :only => [:edit,:show,:update]

  def index
    flash[:warning]="You need to log in."
    redirect_to new_user_session_path
  end

  def setup_attributes
    @document_fedora = Hydrus::Collection.find(params[:id])
    @document_fedora.current_user = current_user
  end

  def show
  end

  def edit
  end

  def new
    collection = Hydrus::Collection.create(current_user)
    collection.current_user = current_user
    redirect_to edit_polymorphic_path(collection)
  end

  def update

    notice = []

    ####
    # Update attributes without saving.
    ####

    if params.has_key?("hydrus_collection")
      @document_fedora.attributes = params["hydrus_collection"]
    end

    ####
    # Handle requests to add to multi-valued fields.
    ####

    has_mvf = (
      params.has_key?(:add_link) or
      params.has_key?(:add_person)
    )

    if has_mvf
      if params.has_key?(:add_link)
        @document_fedora.descMetadata.insert_related_item
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
        if params.has_key?(:add_link)
          render "add_link", :locals=>{:index=>@document_fedora.related_item_title.length-1}
        elsif params.has_key?(:add_person)
          render "add_person", :locals=>{:add_index=>@document_fedora.person_id.length-1}
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

end
