desc "Run Continuous Integration Suite (tests, coverage, docs)" 
task :ci do 
  Rake::Task["hydrus:config"].invoke
  Rake::Task["hydra:jetty:config"].invoke

  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    :jetty_port => 8983,
    :startup_wait => 25
  })
  
  error = nil
  error = Jettywrapper.wrap(jetty_params) do
    Rails.env = "test"
    original_coverage = ENV['COVERAGE']
    Rake::Task['hydrus:refreshfix'].invoke
    ENV['COVERAGE'] ||= 'true'
    Rake::Task['rspec'].invoke
    ENV['COVERAGE'] = original_coverage || 'false'
    Rake::Task['rspec_with_integration'].invoke
  end
  raise "TEST FAILURES: #{error}" if error
  Rake::Task["doc:reapp"].invoke
end


desc "Stop jetty, run `rake ci`, db:migrate, start jetty." 
task :local_ci do 
  # Rails.env = "test" causes error /spec/integration/item_edit_spec.rb:205
  # Item edit editing related content w/o titles
  #Rails.env = "test"
  sub_tasks = %w(jetty:stop db:migrate ci jetty:start)
  sub_tasks.each { |st| Rake::Task[st].invoke }
end
