# This tells Jettywrapper where to download from
ZIP_URL = 'https://github.com/sul-dlss/fcrepo3-jetty/archive/master.zip'.freeze

desc 'Run Continuous Integration Suite (tests, coverage, docs)'
task ci: [:rubocop] do
  unless Rails.env.test?
    # force any CI sub-tasks to run in the test environment (e.g. to ensure
    # fixtures get loaded into the right places)
    system('RAILS_ENV=test rake ci')
    next
  end

  Rake::Task['db:migrate'].invoke
  Rake::Task['jetty:clean'].invoke

  jetty_params = Jettywrapper.load_config.merge({
    jetty_home: File.expand_path(File.dirname(__FILE__) + '../../../jetty'),
    startup_wait: 90
  })

  error = nil
  error = Jettywrapper.wrap(jetty_params) do
    SolrWrapper.wrap do |solr|
      solr.with_collection(name: 'hydrus-test',
                           dir: File.join(File.expand_path('../..', File.dirname(__FILE__)), 'solr_conf', 'conf')) do
        Rake::Task['hydrus:refreshfix'].invoke
        Rake::Task['spec'].invoke
      end
    end
  end
  raise "TEST FAILURES: #{error}" if error
end
