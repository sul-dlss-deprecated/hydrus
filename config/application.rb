require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hydrus
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.eager_load_paths += %W(#{config.root}/lib #{config.root}/lib/validators)
  end
end

GOOGLE_ANALYTICS_CODE = 'UA-7219229-23' # GA tracking ID for sdr.stanford.edu

# Store the Hydrus app's version.
Hydrus::Application.config.app_version = IO.read(File.join(Rails.root, 'VERSION')).strip
Hydrus::Application.config.default_item_type = 'dataset' # default item type to create

Hydrus::Application.config.contact_us_topics = { 'question' => 'Ask a question', 'feedback' => 'Provide Feedback', 'error' => 'Report a problem', 'join' => 'Become an SDR depositor' } # sets the list of topics shown in the contact us page
Hydrus::Application.config.contact_us_recipients = { 'error' => 'sdr-contact@lists.stanford.edu', 'question' => 'sdr-contact@lists.stanford.edu', 'feedback' => 'sdr-contact@lists.stanford.edu', 'join' => 'sdr-contact@lists.stanford.edu' } # sets the email address for each contact us topic configed above
Hydrus::Application.config.contact_us_cc_recipients = { 'error' => '', 'question' => '', 'feedback' => '', 'join' => '' } # sets the CC email address for each contact us topic configed above
