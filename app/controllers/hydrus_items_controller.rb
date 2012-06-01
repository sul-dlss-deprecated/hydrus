class HydrusItemsController < ApplicationController

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  include Hydrus::AccessControlsEnforcement

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
    notice = []
    
    # special case for comma delimited keywords.
    if params.has_key?(:hydrus_item_keywords)
      keywords = {}
      params[:hydrus_item_keywords].split(",").map{|k| k.strip}.each_with_index do |keyword, index|
        keywords[index] = keyword
      end    
      @sanitized_params["descMetadata"].merge!({[:subject, :topic] => keywords})
    end
    
    # Files from the file input.
    if params.has_key?("files")
      params["files"].each do |file|
        new_file = Hydrus::ObjectFile.new
        new_file.pid = params[:id]
        new_file.label = params["file_label"][new_file.id] if params.has_key?("file_label") and params["file_label"][new_file.id]
        new_file.file = file
        new_file.save
        new_file.label
        notice << "'#{file.original_filename}' uploaded."
      end
    end
    
    # The file labels.
    if params.has_key?("file_label")
      params["file_label"].each do |id,label|
        file = Hydrus::ObjectFile.find(id)
        file.label = label
        file.save
      end
    end
    
    @response = update_document(@document_fedora, @sanitized_params)
    if params.has_key?(:add_person)
      @document_fedora.descMetadata.insert_person
    elsif params.has_key?(:add_link)
      @document_fedora.descMetadata.insert_related_item
    end
    logger.debug("attributes submitted: #{@sanitized_params.inspect}")
    @document_fedora.save
    
    notice << "Your changes have been saved."
    flash[:notice] = notice.join("<br/>").html_safe unless notice.blank?
    
    respond_to do |want|
      want.html {
        if params.has_key?(:add_person) or params.has_key?(:add_link)
          # if we want to pass on parameters to edit screen we'll need to use the named route
          #redirect_to edit_polymorphic_path(@document_fedora, :my_param=>"oh-hai-there")
          redirect_to [:edit, @document_fedora]
        else
          redirect_to @document_fedora
        end
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
