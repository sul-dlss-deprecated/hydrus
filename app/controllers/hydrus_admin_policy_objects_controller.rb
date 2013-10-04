class HydrusAdminPolicyObjectsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior

  def show
    @fobj = Hydrus::AdminPolicyObject.find(params[:id])
    authorize! :read, @fobj
    redirect_to hydrus_admin_policy_object_datastreams_path(@fobj)
  end

end
