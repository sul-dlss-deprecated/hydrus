class ObjectFilesController < ApplicationController
  
  def create
    # Binary Base64 files from drag-and-drop.
    if params.has_key?("binary_data")
      binary_file = params["binary_data"].gsub(/^.*;base64,/, "")
      temp_file = StringIO.new(Base64.decode64(binary_file))
      temp_file.class_eval { attr_accessor :original_filename }
      temp_file.original_filename = params["file_name"]
      new_file = Hydrus::ObjectFile.new
      new_file.pid = params[:id]
      new_file.file = temp_file
      new_file.save
      @file = new_file
    end    
  end
  
  def destroy
    object_file=Hydrus::ObjectFile.find(params[:id]).destroy  # this will also delete the underlying file from the local Hydrus file system upload location
    @id=object_file.id

    respond_to do |want|
       want.html {
         flash[:warning]="The file was deleted."
         redirect_to hydrus_item_url(object_file.pid)
       }
       want.js {
         render :action=>:destroy
       }
     end

  end
  
end