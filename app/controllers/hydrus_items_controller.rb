class HydrusItemsController < ApplicationController

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes
  
  def index
    flash[:warning]="You need to log in."
    redirect_to new_user_session_path
  end  

  def setup_attributes
    @document_fedora = Hydrus::Item.find(params[:id])
  end

  def show
  end

  def edit
  end

  def update
    logger.debug("attributes submitted: #{@sanitized_params.inspect}")
    @response = update_document(@document_fedora, @sanitized_params)
    @document_fedora.save
    flash[:notice] = "Your changes have been saved."
    respond_to do |want|
      want.html {
        redirect_to @document_fedora
      }
      want.js {
        if params.has_key?(:add_person)
          render "add_person", :locals=>{:index=>params[:add_person]}
        elsif params.has_key?(:add_link)
          render "add_link", :locals=>{:index=>params[:add_link]}
        else
          render :json => tidy_response_from_update(@response) unless params.has_key?(:add_person)
        end
      }
    end
  end

end
