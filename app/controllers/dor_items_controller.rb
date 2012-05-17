class DorItemsController < ApplicationController

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  prepend_before_filter :sanitize_update_params, :only => :update

  def setup_attributes
    @pid              = params[:id]
    @document_fedora  = ActiveFedora::Base.find(@pid, :cast => true)
    @descMetadata     = @document_fedora.descMetadata
    @dcMetadata       = @document_fedora.DC
    @identityMetadata = @document_fedora.identityMetadata
    @apo_pid          = @document_fedora.admin_policy_object_ids.first
    @apo              = @apo_pid ? ActiveFedora::Base.find(@apo_pid, :cast => true) : nil
  end

  def show
    setup_attributes
  end

  def edit
    setup_attributes
  end

  def update
    setup_attributes
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
