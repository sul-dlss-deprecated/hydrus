# A mixin for contentMetadata stuff.

module Hydrus::Contentable

  # Generates the object's contentMetadata XML, stores the XML in the
  # object's datastreams, and writes the XML to a file.
  def update_content_metadata
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
    if is_item?
      objects = files.map { |f| Assembly::ObjectFile.new(f.current_path, :label => f.label) }
    else
      objects = []
    end
    return Assembly::ContentMetadata.create_content_metadata(
      :druid               => pid,
      :objects             => objects,
      :add_file_attributes => true,
      :style               => Hydrus::Application.config.cm_style,
      :file_attributes     => Hydrus::Application.config.cm_file_attributes,
      :include_root_xml    => false)
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
