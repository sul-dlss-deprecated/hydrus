Jettywrapper.hydra_jetty_version = 'v7.0.0'

desc 'Run Continuous Integration Suite (tests, coverage, docs)'
task ci: [:rubocop, 'jetty:clean', 'jetty:config'] do
  unless Rails.env.test?
    # force any CI sub-tasks to run in the test environment (e.g. to ensure
    # fixtures get loaded into the right places)
    system('RAILS_ENV=test rake ci')
    next
  end

  Rake::Task['db:migrate'].invoke

  jetty_params = Jettywrapper.load_config.merge({
    jetty_home: File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    startup_wait: 90
  })

  error = nil
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['hydrus:refreshfix'].invoke
    Rake::Task['spec'].invoke
  end
  raise "TEST FAILURES: #{error}" if error
end
