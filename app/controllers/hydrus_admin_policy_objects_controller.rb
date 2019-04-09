class HydrusAdminPolicyObjectsController < ApplicationController
  before_action :authenticate_user!

  def show
    @fobj = Hydrus::AdminPolicyObject.find(params[:id])
    authorize! :read, @fobj
    redirect_to hydrus_admin_policy_object_datastreams_path(@fobj)
  end
end
