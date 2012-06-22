class HydrusItemsController < ApplicationController

  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  include Hydrus::AccessControlsEnforcement

  #prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes
  before_filter :check_for_collection, :only => :new
  
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
  
  def new
    collection = Hydrus::Collection.find(params[:collection])
    # We will probably want to refactor this out somewhere to be reused for creating collections.
    apo = collection.apo_pid
    registration_params = {
      :object_type  => 'item',
      :admin_policy => apo,
      :source_id    => { "Hydrus" => "#{current_user}-#{Time.now}" },
      :label        => "Hydrus",
      :tags         => ["Project : Hydrus"]
    }
    dor_item = Dor::RegistrationService.register_object registration_params
    item = dor_item.adapt_to(Hydrus::Item)
    item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
    item.assert_content_model
    item.add_to_collection(collection.pid)
    item.save
    redirect_to edit_polymorphic_path(item)
  end

  def update
    notice = []
    
    # special case for editing multi-valued field as comma delimted string.
    if params.has_key?("hydrus_item_keywords") and @document_fedora.keywords.sort != params["hydrus_item_keywords"].split(",").map{|k| k.strip }.sort
      # need to clear out all keywords from document as the hydrus_item_keywords is the canonical list of keywords.
      @document_fedora.update_attributes({"keywords" => {0=>""}})
      keywords = {}
      params["hydrus_item_keywords"].split(",").map{|k| k.strip}.each_with_index do |keyword, index|
        keywords[index] = keyword
      end
      params["hydrus_item"].merge!("keywords" => keywords)
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
    
    @document_fedora.update_attributes(params["hydrus_item"]) if params.has_key?("hydrus_item")
    if params.has_key?(:add_person)
      @document_fedora.descMetadata.insert_person
    elsif params.has_key?(:add_link)
      @document_fedora.descMetadata.insert_related_item
    elsif params.has_key?(:add_related_citation)
      @document_fedora.descMetadata.insert_related_citation
    end
    logger.debug("attributes submitted: #{params['hydrus_item'].inspect}")
    
    if @document_fedora.valid?
      @document_fedora.save
    else
      errors = []  
      @document_fedora.errors.messages.each do |field, error|
        errors << "#{field.to_s.humanize.capitalize} #{error.join(', ')}"
      end
      flash[:error] = errors.join("<br/>").html_safe
      redirect_to [:edit, @document_fedora] and return
    end  
      
    
    notice << "Your changes have been saved."
    flash[:notice] = notice.join("<br/>").html_safe unless notice.blank?
    
    respond_to do |want|
      want.html {
        if params.has_key?(:add_person) or params.has_key?(:add_link) or params.has_key?(:add_related_citation)
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
        elsif params.has_key?(:add_related_citation)
          render "add_related_citation", :locals=>{:index=>params[:add_related_citation]}
        else
          render :json => tidy_response_from_update(@response) unless params.has_key?(:add_person)
        end
      }
    end
  end

  def destroy_value
    @document_fedora.descMetadata.remove_node(params[:term], params[:term_index])
    @document_fedora.save
    respond_to do |want|
      want.html {redirect_to :back}
      want.js 
    end
  end

  protected
  
  def check_for_collection
    unless params.has_key?(:collection)
      flash[:error] = "You cannot create an item without specifying a collection."
      redirect_to root_path
    end
  end

end
