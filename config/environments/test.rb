Hydrus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

end

Dor::Config.configure do

  purl do
    base_url 'http://purl.stanford.edu/'
  end

  hydrus do
    exception_error_page  false                   # if true, a generic error page will be shown with no exception messages; if false, standard Rails exceptions are shown directly to the user
    exception_error_panel false                   # if true and exception_error_page is also set to true, a collapsible exception error panel is shown on the friendly error page
    exception_recipients  ''                      # list of email addresses, comma separated, that will be notified when an exception occurs - leave blank for no emails
    host 'localhost:3000'                       # server host, used in emails
    start_common_assembly(false)                # determines if assembly workflow is started when publishing

    # complete list of all workflow objects defined in this environment
    workflow_object_druids [
      'druid:oo000oo0099',  # hydrusAssemblyWF
      'druid:oo000oo0098',  # versioningWF
    ]

  end

end
