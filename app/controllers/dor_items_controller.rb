class DorItemsController < ApplicationController

  # TODO: need to enforce access controls.

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  def show
    @pid              = params[:id]
    @document_fedora  = ActiveFedora::Base.find(@pid, :cast => true)
    @descMetadata     = @document_fedora.descMetadata
    @dcMetadata       = @document_fedora.DC
    @identityMetadata = @document_fedora.identityMetadata
  end

end
