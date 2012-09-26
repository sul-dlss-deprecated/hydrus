class EventsController < ApplicationController
  
  include Hydra::AccessControlsEnforcement
  before_filter :enforce_access_controls
  
  def index
    contextual_id = params.select{|k,v| k.to_s =~ /^hydrus_.*_id/}.each_value.first
    unless contextual_id.blank?
      @document_fedora = ActiveFedora::Base.find(contextual_id, :cast=>true)
      @document_fedora.current_user = current_user
    end
  end
  
  protected
  
  def enforce_index_permissions
    contextual_id = params.select{|k,v| k.to_s =~ /^hydrus_.*_id/}.each_value.first
    if contextual_id.blank? or !can?(:read, contextual_id)
      flash[:error] = "You do not have sufficient privileges to read that document."
      redirect_to root_path
    end
  end
  
end