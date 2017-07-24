class ObjectFilesController < ApplicationController

  before_filter :authenticate_user!

  def show
    @fobj = Hydrus::Item.find(params[:id])
    @fobj.current_user = current_user
    authorize! :read, @fobj # only users who are authorized to view this object and download the files
    filename = params[:filename]      
    object_file = Hydrus::ObjectFile.new(:pid=>DruidTools::Druid.new(@fobj.pid).druid)
    file_location = File.join(object_file.file.store_dir,filename)
    file = File.new(file_location)
    send_file file
  end
  
end
