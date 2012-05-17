class HydrusItemsController < ApplicationController

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :setup_attributes

  def setup_attributes
    @document_fedora  = Hydrus::Item.find(params[:id])
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
