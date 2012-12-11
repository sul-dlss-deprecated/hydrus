class DatastreamsController < ApplicationController

  include Hydra::AccessControlsEnforcement
  before_filter :enforce_access_controls

  def index
    pid = obj_pid()
    @fobj = ActiveFedora::Base.find(pid, :cast=>true)
    @fobj.current_user = current_user
  end

  protected

  def enforce_index_permissions
    pid = obj_pid()
    return if pid && can?(:view_datastreams, pid)
    flash[:error] = "You do not have sufficient privileges to view datastreams."
    redirect_to root_path
  end

  def obj_pid
    pid = params['hydrus_item_id'] || params['hydrus_collection_id']
    return pid
  end

end
