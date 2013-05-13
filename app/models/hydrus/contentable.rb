# A mixin for contentMetadata stuff.

module Hydrus::Contentable

  # Check to see if all of the files that are referenced in the database actually exist on the file system
  def files_missing?
    files.map{|f| f.missing?}.include?(true)
  end
  
  # remove any files deemed missing from the database; return the number deleted
  def delete_missing_files
    files_missing=0
    files.each do |f|
      if f.missing?
        f.destroy
        files_missing+=1
      end 
    end
    return files_missing
  end
    
  # Generates the object's contentMetadata XML, stores the XML in the
  # object's datastreams, and writes the XML to a file.
  def update_content_metadata
    # return unless is_item? # TODO We can stop creating content metadata once the assembly robots are smart enough to deal with it not being there for APOs and Collections
    # Set the object's contentMetadata.
    xml = create_content_metadata_xml()
    datastreams['contentMetadata'].content = xml
    # Write XML to file, provided that the druid is valid.
    return unless DruidTools::Druid.valid?(pid)
    FileUtils.mkdir_p(metadata_directory)
    fname = File.join(metadata_directory, 'contentMetadata.xml')
    File.open(fname, 'w') { |fh| fh.puts xml }
  end

  # Generates and returns a string of contentMetadata XML for the object.
  def create_content_metadata_xml 
 #   return "" unless is_item? # only need contentMetadata for item types # TODO We can stop creating content metadata once the assembly robots are smart enough to deal with it not being there for APOs and Collections
    conf = Hydrus::Application.config
    objects = []
    if is_item?
      files.each { |f|
        aof = Assembly::ObjectFile.new(f.current_path)
        aof.label = f.label
        aof.file_attributes = conf.cm_file_attributes_hidden if f.hide
        objects << aof
      }
    end
    return Assembly::ContentMetadata.create_content_metadata(
      :druid               => pid,
      :objects             => objects,
      :add_file_attributes => true,
      :style               => conf.cm_style,
      :file_attributes     => conf.cm_file_attributes,
      :auto_labels         => false,
      :include_root_xml    => false)
  end

  def parent_directory
    return File.expand_path(File.join(base_file_directory, '..'))
  end

  def base_file_directory
    f = File.join(Rails.root, "public", Hydrus::Application.config.file_upload_path)
    DruidTools::Druid.new(pid, f).path
  end

  def content_directory
    File.join(base_file_directory, "content")
  end

  def metadata_directory
    File.join(base_file_directory, "metadata")
  end

end
