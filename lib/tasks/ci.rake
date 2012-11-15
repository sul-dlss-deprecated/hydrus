desc "Run Continuous Integration Suite (tests, coverage, docs)"
task :ci do
  Rake::Task["hydrus:config"].invoke
  Rake::Task["hydra:jetty:config"].invoke

  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    :jetty_port => 8983,
    :startup_wait => 200
  })

  error = nil
  error = Jettywrapper.wrap(jetty_params) do
    Rails.env = "test"
    original_coverage = ENV['COVERAGE']
    Rake::Task['hydrus:refreshfix'].invoke
    ENV['COVERAGE'] ||= 'true'
    Rake::Task['rspec_all'].invoke
    ENV['COVERAGE'] = original_coverage || 'false'
  end
  raise "TEST FAILURES: #{error}" if error
  Rake::Task["doc:reapp"].invoke
end

desc "Run only unit tests with coverage report, assumes jetty is running already and no fixture refreshes"
task :unit_tests do
  ENV['RAILS_ENV'] = 'test'
  Rails.env = 'test'
  ENV['COVERAGE'] = 'true'
  Rake::Task['rspec'].invoke
end

desc "Run only integrations tests with coverage report, assumes jetty is running already and no fixture refreshes"
task :integration_tests do
  ENV['RAILS_ENV'] = 'test'
  Rails.env = 'test'
  ENV['COVERAGE'] = 'true'
  Rake::Task['rspec_with_integration'].invoke
end

desc "Stop jetty, run `rake ci`, db:migrate, start jetty."
task :local_ci do
  ENV['RAILS_ENV'] = 'test'
  Rails.env = 'test'
  sub_tasks = %w(jetty:stop db:migrate ci jetty:start)
  sub_tasks.each { |st| Rake::Task[st].invoke }
end

desc "Runs ci task in another directory on another jetty port, so you can keep working"
task :ci_alt do
  src   = File.absolute_path('.')
  dst   = File.absolute_path(ENV['DEST'] || '../alt_hydrus')
  files = "lib/tasks/ci.rake config/fedora.yml config/solr.yml"
  cmds = [
    "rsync --archive --delete --quiet #{src}/ #{dst}/",
    "cd #{dst}",
    "perl -p -i -e 's/8983/8984/g' #{files}",
    "rake ci",
  ]
  puts "Will run `rake ci` on port 8984 in #{dst}."
  system cmds.join(' && ')
end

