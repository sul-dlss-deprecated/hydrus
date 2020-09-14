class DatastreamsController < ApplicationController
  before_action do
    if contextual_id.blank?
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  before_action :authenticate_user!

  def index
    pid = contextual_id
    authorize! :view_datastreams, pid
    @fobj = ActiveFedora::Base.find(pid, cast: true)
    @fobj.current_user = current_user
  end
end
