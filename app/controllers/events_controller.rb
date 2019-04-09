class EventsController < ApplicationController
  before_action do
    if contextual_id.blank?
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  before_action :authenticate_user!

  def index
    @fobj = ActiveFedora::Base.find(contextual_id, cast: true)
    @fobj.current_user = current_user
    authorize! :read, @fobj
  end

  protected

  def contextual_id
    @contextual_id ||= params.select { |k, v| k.to_s =~ /^hydrus_.*_id/ }.to_unsafe_hash.each_value.first
  end
end
