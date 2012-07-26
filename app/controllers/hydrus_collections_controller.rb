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
    @document_fedora  = Hydrus::Collection.find(params[:id])
  end

  def show
  end

  def edit
  end

  def new
    collection = Hydrus::Collection.create(current_user)
    redirect_to edit_polymorphic_path(collection)
  end

  def update
    notice = []
    phc = params["hydrus_collection"]

    @document_fedora.update_attributes(phc) if phc
    if params.has_key?(:add_link)
      @document_fedora.descMetadata.insert_related_item
    elsif params.has_key?(:add_person)
      @document_fedora.add_empty_person_to_role(Hydrus::AdminPolicyObject.default_role)
    end

#    logger.debug("attributes submitted: #{params['hydrus_collection'].inspect}")
    
    if @document_fedora.object_valid?
      @document_fedora.save
    else
      # invalid collection, generate errors to display to user
      errors = []  
      @document_fedora.object_error_messages.each do |field, error|
        errors << "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
      end
      flash[:error] = errors.join("<br/>").html_safe
      render :edit and return
    end  
    
    notice << "Your changes have been saved."
    flash[:notice] = notice.join("<br/>").html_safe unless notice.blank?
    
    respond_to do |want|
      want.html {
        if params.has_key?(:add_link) or params.has_key?(:add_person)
          # if we want to pass on parameters to edit screen we'll need to use the named route
          #redirect_to edit_polymorphic_path(@document_fedora, :person_role=>"collection_viewer")
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
  end # update

  def destroy_value
    @document_fedora.descMetadata.remove_node(params[:term], params[:term_index])
    @document_fedora.save
    respond_to do |want|
      want.html {redirect_to :back}
      want.js
    end
  end

  # remove an 'actor' (person or group) form the roleMetadata
  def destroy_actor
    @document_fedora.remove_actor(params[:actor_id], params[:role])
    @document_fedora.save
    respond_to do |want|
      want.html {redirect_to :back}
      want.js
    end
  end

end
