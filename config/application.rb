require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Get unbuffered STDOUT (even when redirecting) in development mode.
STDOUT.sync = true if Rails.env == 'development'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Hydrus
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/validators)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Pacific Time (US & Canada)'
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end

# Store the Hydrus app's version.
Hydrus::Application.config.app_version = IO.read(File.join(Rails.root, 'VERSION')).strip
Hydrus::Application.config.default_item_type='dataset' # default item type to create

Hydrus::Application.config.contact_us_topics = {'error'=>"Problem with the website",'question'=>"Ask a question",'feedback'=>"Provide feedback"} # sets the list of topics shown in the contact us page
Hydrus::Application.config.contact_us_recipients = {'error'=>'sdr-contact@lists.stanford.edu','question'=>'sdr-contact@lists.stanford.edu','feedback'=>'sdr-contact@lists.stanford.edu'} # sets the email address for each contact us topic configed above
Hydrus::Application.config.contact_us_cc_recipients = {'error'=>'','question'=>'','feedback'=>''} # sets the CC email address for each contact us topic configed above

