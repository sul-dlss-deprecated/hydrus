class Hydrus::ObjectFile < ActiveRecord::Base
  
  attr_accessible :label,:pid
  
  mount_uploader :file, FileUploader
    
  def size
    file.size
  end
  
  def url
    file.url
  end
  
  def current_path
    file.current_path
  end
      
  def filename
    file.file.identifier
  end
  
end
