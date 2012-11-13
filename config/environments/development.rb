Hydrus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  
  
end

Dor::Config.configure do

  purl do
    base_url 'http://purl.stanford.edu/'
  end
  
  hydrus do
    exception_error_page  false                   # if true, a generic error page will be shown with no exception messages; if false, standard Rails exceptions are shown directly to the user
    exception_error_panel false                   # if true and exception_error_page is also set to true, a collapsible exception error panel is shown on the friendly error page
    exception_recipients  ''                      # list of email addresses, comma separated, that will be notified when an exception occurs - leave blank for no emails
    workflow_object_druids ['druid:oo000oo0099']  # complete list of all workflow objects defined in this environment
    host 'localhost:3000'                         # server host, used in emails
    start_common_assembly(false)                  # determines if assembly workflow is started when publishing
  end

end