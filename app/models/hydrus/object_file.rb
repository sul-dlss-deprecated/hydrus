class Hydrus::ObjectFile < ActiveRecord::Base
  include Hydrus::ModelHelper

  mount_uploader :file, FileUploader
  after_destroy :remove_file!

  def size
    file.size
  end
  
  # Override the URL supplied by CarrierWave
  def url
    Rails.application.routes.url_helpers.file_upload_path(:id=>pid,:filename=>filename)
  end

  def current_path
    file.current_path
  end

  # is this file missing on the file system?
  def missing?
    file.file.nil? || File.exists?(file.current_path) == false
  end

  def filename
    file.file.nil? ? '' : file.file.identifier # don't throw exception if file is blank so the page doesn't show an exception
  end

  def is_dupe?(new_filename)
    self.class.where('pid=? and file=?', pid, new_filename).size > 0
  end

  def dupes
    self.class.where('pid=? and file=? and id!=?', pid, filename, id)
  end

  # any given object can only have one file with the same name; if the user uploads a new file with the same name as an existing file, the dupe will be removed
  def remove_dupes
    dupes.each { |dupe| dupe.delete }
  end

  # A convenience uber-setter to simplify controller code.
  #
  # Takes nil or a hash with possible keys of 'label' and 'hide'.
  # Calls the underlying setters if the new values differ from current values.
  #
  # Returns true if changes were made to the object.
  def set_file_info(h)
    # Handle nil and normalize the values.
    return false if h.nil?
    lab = h['label'] || ''
    hid = to_bool(h['hide'])
    # Do nothing if new values are the same as current values.
    return false if (lab == label && hid == hide)
    # Set new values.
    self.label = lab
    self.hide  = hid
    true
  end

  # A getter that parallels set_file_info(), but using symbols as keys.
  # Written mainly to facilitate testing.
  def get_file_info
    {
      label: label,
      hide: hide,
    }
  end
end
