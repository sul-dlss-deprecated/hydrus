class EventsController < ApplicationController
  
  include Hydrus::AccessControlsEnforcement
  
  #prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :redirect_if_not_correct_object_type, :only => [:edit,:show,:update]
  
  def index
    contextual_id = params.select{|k,v| k.to_s =~ /^hydrus_.*_id/}.each_value.first
    @document_fedora = ActiveFedora::Base.find(contextual_id, :cast=>true)
    @document_fedora.current_user = current_user
  end
  
end