class DorItemsController < ApplicationController

  # TODO: need to enforce access controls.

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  def show
    setup_attributes
  end

  def edit
    setup_attributes
  end

  def setup_attributes
    @pid              = params[:id]
    @document_fedora  = ActiveFedora::Base.find(@pid, :cast => true)
    @descMetadata     = @document_fedora.descMetadata
    @dcMetadata       = @document_fedora.DC
    @identityMetadata = @document_fedora.identityMetadata
  end

end
