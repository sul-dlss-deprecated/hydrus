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

end
