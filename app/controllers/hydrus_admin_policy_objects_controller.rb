class HydrusAdminPolicyObjectsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  before_filter :enforce_access_controls

  def show
    @fobj = Hydrus::AdminPolicyObject.find(params[:id])
    redirect_to hydrus_admin_policy_object_datastreams_path(@fobj)
  end

end
