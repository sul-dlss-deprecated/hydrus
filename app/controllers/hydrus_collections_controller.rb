class HydrusCollectionsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => :new

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
    apo = create_apo(current_user)
    dor_item = Hydrus::GenericObject.register_dor_object(current_user, 'collection', apo.pid)
    collection = dor_item.adapt_to(Hydrus::Collection)
    collection.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Collection'
    collection.assert_content_model
    #TODO:  Initialize roleMetadata datastream with the collection-manager role for the current logged-in user
    collection.save
    redirect_to edit_polymorphic_path(collection)
  end

  def create_apo(user)
    args = [user, 'adminPolicy', Dor::Config.ur_apo_druid]
    apo  = Hydrus::GenericObject.register_dor_object(*args)
    apo  = apo.adapt_to(Hydrus::AdminPolicyObject)
    apo.remove_relationship :has_model, 'info:fedora/afmodel:Dor_AdminPolicyObject'
    apo.assert_content_model
    apo.save
    return apo
  end

  def update
    @document_fedora.update_attributes(params["hydrus_collection"]) if params.has_key?("hydrus_collection")
    if params.has_key?(:add_link)
      @document_fedora.descMetadata.insert_related_item
    elsif params.has_key?(:add_person)
      @document_fedora.apo.roleMetadata.add_person_of_role('from_controller')
    end
#    logger.debug("attributes submitted: #{params['hydrus_collection'].inspect}")
    
    # TODO: validate doc!
#    puts "DEBUG: before save: #{@document_fedora.apo.roleMetadata.to_xml}"
    @document_fedora.save
#    puts "DEBUG: after save: #{@document_fedora.apo.roleMetadata.to_xml}"
    
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
          render "add_link", :locals=>{:index=>params[:add_link]}
        elsif params.has_key?(:add_person)
          render "add_person", :locals=>{:index=>params[:add_person]}
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

  protected :create_apo

end
