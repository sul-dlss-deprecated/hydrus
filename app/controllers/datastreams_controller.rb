# frozen_string_literal: true
class DatastreamsController < ApplicationController
  before_filter do
    if contextual_id.blank?
      raise ActionController::RoutingError.new('Not Found')
    end
  end
  
  before_filter :authenticate_user!

  def index
    pid = contextual_id()
    authorize! :view_datastreams, pid
    @fobj = ActiveFedora::Base.find(pid, cast: true)
    @fobj.current_user = current_user
  end

  protected

  def contextual_id
    @contextual_id ||= params.select{ |k,v| k.to_s =~ /^hydrus_.*_id/ }.each_value.first
  end

end
