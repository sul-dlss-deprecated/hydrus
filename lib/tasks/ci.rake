ZIP_FILE = 'https://github.com/projecthydra/hydra-jetty/archive/v7.3.1.zip'

desc "Run Continuous Integration Suite (tests, coverage, docs)"
task :ci => ['jetty:clean', 'jetty:config'] do
  unless Rails.env.test?
    # force any CI sub-tasks to run in the test environment (e.g. to ensure
    # fixtures get loaded into the right places)
    system('RAILS_ENV=test rake ci')
    next
  end

  Rake::Task["db:migrate"].invoke

  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    :jetty_port => 8983,
    :startup_wait => 200
  })

  error = nil
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['hydrus:refreshfix'].invoke
    Rake::Task['spec'].invoke
  end
  raise "TEST FAILURES: #{error}" if error
end
