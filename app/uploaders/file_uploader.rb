# encoding: utf-8

class FileUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # allow any character in the uploaded filename - see https://github.com/jnicklas/carrierwave
  CarrierWave::SanitizedFile.sanitize_regexp = /$^/

  # Choose what kind of storage to use for this uploader:
  storage :file

  before :store, :remember_cache_id
  after :store, :delete_tmp_dir

  ##
  # By default, CarrierWave copies an uploaded file twice, first copying the file into the cache, then copying the file into the store.
  # For large files, this can be prohibitively time consuming.
  # You may change this behavior by overriding either or both of the move_to_cache and move_to_store methods and set values to true.
  def move_to_cache
    true
  end

  def move_to_store
    true
  end
  ##

  # store! nil's the cache_id after it finishes so we need to remember it for deletion
  def remember_cache_id(new_file)
    @cache_id_was = cache_id
  end

  def delete_tmp_dir(new_file)
    # make sure we don't delete other things accidentally by checking the name pattern
    if @cache_id_was.present? && @cache_id_was =~ /\A[\d]{8}\-[\d]{4}\-[\d]+\-[\d]{4}\z/
      FileUtils.rm_rf(File.join(root, cache_dir, @cache_id_was))
    end
  end

  # Set the base object directory name
  def base_dir
    File.join(Rails.root, Settings.hydrus.file_upload_path, DruidTools::Druid.new(model.pid).path)
  end
    
  # Set the directory where uploaded files will be stored.
  def store_dir
    File.join(base_dir, 'content')
  end

  # temp directory where files are stored before they are uploaded
  def cache_dir
    File.join(Rails.root,'tmp')
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
