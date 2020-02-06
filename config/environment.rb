# Load the Rails application
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

Hydrus::Application.configure do
  # file attributes by mimetype, including defaults, to use when generating content metadata
  config.cm_file_attributes = {
    'default' => { publish: 'yes', preserve: 'yes', shelve: 'yes' }
  }
  config.cm_file_attributes_hidden = { publish: 'no', preserve: 'yes', shelve: 'no' }

  # style of content metadata to generate
  config.cm_style = :file
end
