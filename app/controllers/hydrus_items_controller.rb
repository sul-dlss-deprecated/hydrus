class HydrusItemsController < ApplicationController

  include Hydra::Controller::ControllerBehavior
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::Controller::UploadBehavior
  include Hydrus::AccessControlsEnforcement

  #prepend_before_filter :sanitize_update_params, :only => :update
  before_filter :enforce_access_controls
  before_filter :setup_attributes, :except => :new
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
    dor_item   = Hydrus::GenericObject.register_dor_object(current_user, 'item', collection.apo_pid)
    item       = dor_item.adapt_to(Hydrus::Item)
    item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
    item.assert_content_model
    item.add_to_collection(collection.pid)
    item.save
    redirect_to edit_polymorphic_path(item)
  end

  # Takes a comma-delimited string of keywords, as entered in the UI.
  # Returns a hash like this: { 0 => 'foo', 1 => 'bar bar', etc. }
  # Leading and trailing whitespace is removed from the keywords.
  def parse_keywords(kws)
    Hash[ kws.strip.split(/\s*,\s*/).each_with_index.map { |kw,i| [i,kw] } ]
  end

  def update
    notice = []
    
    # Handle keywords (topics), which user supplies as a comma-delimited string.
    if params.has_key?("hydrus_item_keywords")
      kws = parse_keywords(params['hydrus_item_keywords'])
      params["hydrus_item"]["keywords"] = kws unless @document_fedora.keywords == kws.values
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
#    logger.debug("attributes submitted: #{params['hydrus_item'].inspect}")
    
    if @document_fedora.valid?
      @document_fedora.save
    else
      # invalid item, generate errors to display to user
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
