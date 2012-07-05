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
    collection.save
    redirect_to edit_polymorphic_path(collection)
  end

  def create_apo(user)
    return Hydrus::GenericObject.register_dor_object(
      user, 'adminPolicy', Dor::Config.ur_apo_druid)
  end

  def update
    @document_fedora.update_attributes(params["hydrus_collection"]) if params.has_key?("hydrus_collection")
    @document_fedora.descMetadata.insert_related_item if params.has_key?(:add_link)
    @document_fedora.save
    flash[:notice] = "Your changes have been saved."
    respond_to do |want|
      want.html {
        if params.has_key?(:add_link)
          redirect_to [:edit, @document_fedora]
        else
          redirect_to @document_fedora
        end
      }
      want.js {
        if params.has_key?(:add_link)
          render "add_link", :locals=>{:index=>params[:add_link]}
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

  protected :create_apo

end
