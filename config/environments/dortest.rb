Hydrus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # this is the path from the root of the public folder into which file uploads will be stored
  config.file_upload_path = 'uploads'

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
end

Dor::Config.configure do

  purl do
    base_url 'http://purl-test.stanford.edu/'
  end

  hydrus do
    exception_error_page   true     # if true, a generic error page will be shown with no exception messages; if false, standard Rails exceptions are shown directly to the user
    exception_error_panel  true     # if true and exception_error_page is also set to true, a collapsible exception error panel is shown on the friendly error page
    exception_recipients  ''        # list of email addresses, comma separated, that will be notified when an exception occurs - leave blank for no emails
    host 'hydrus-test.stanford.edu' # server host, used in emails
    start_assembly_wf(true)         # determines if assembly workflow is started when publishing

    # complete list of all workflow objects defined in this environment
    workflow_object_druids [
      'druid:oo000oo0099',  # hydrusAssemblyWF
      'druid:rs056hz6024',  # assemblyWF
      'druid:yp220bx1022',  # versioningWF
    ]

  end

end
