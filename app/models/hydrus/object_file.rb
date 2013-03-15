class Hydrus::ObjectFile < ActiveRecord::Base

  include Hydrus::ModelHelper

  attr_accessible :label, :pid, :hide

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
    file.file.nil? ? "" : file.file.identifier # don't throw exception if file is blank for now so the page doesn't totally crap out
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
    return false if (lab == label and hid == hide)
    # Set new values.
    self.label = lab
    self.hide  = hid
    return true
  end

  # A getter that parallels set_file_info(), but using symbols as keys.
  # Written mainly to facilitate testing.
  def get_file_info
    return {
      :label => label,
      :hide  => hide,
    }
  end

end
