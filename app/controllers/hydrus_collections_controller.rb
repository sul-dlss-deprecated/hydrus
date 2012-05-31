class HydrusCollectionsController < ApplicationController

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  include Hydrus::AccessControlsEnforcement

  prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes
  
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

  def update
    logger.debug("attributes submitted: #{@sanitized_params.inspect}")
    @response = update_document(@document_fedora, @sanitized_params)
    @document_fedora.save
    flash[:notice] = "Your changes have been saved."
    respond_to do |want|
      want.html {
        redirect_to @document_fedora
      }
      want.js {
        render :json => tidy_response_from_update(@response)
      }
    end
  end

end
