desc "Run Continuous Integration Suite (tests, coverage, docs)" 

task :ci do 
  Rake::Task["hydra:jetty:config"].invoke

  ENV['COVERAGE'] = 'true' unless ENV.key? 'COVERAGE'
  
  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    :jetty_port => 8983,
    :startup_wait => 25
  })
  
  error = nil
  error = Jettywrapper.wrap(jetty_params) do
      Rake::Task['hydrus:refreshfix'].invoke
      Rake::Task['rspec'].invoke
      # as of 2012-05-23, no longer have cucumber tests
      # Rake::Task['cucumber:ok'].invoke
  end
  raise "TEST FAILURES: #{error}" if error
  Rake::Task["doc:reapp"].invoke
end
