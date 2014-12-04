begin
  require 'rspec/core/rake_task'

  desc "Run all specs, excluding integration"
  RSpec::Core::RakeTask.new(:rspec) do |spec|
    spec.rspec_opts = "--tag ~integration"
  end

  desc "Run only integration specs"
  RSpec::Core::RakeTask.new(:rspec_with_integration) do |spec|
    spec.rspec_opts = "--tag integration"
  end

rescue LoadError
  desc 'rspec rake task not available (rspec not installed)'
  task :rspec do
    abort 'Rspec rake task is not available. Install rspec as a gem or plugin.'
  end
end

desc "Run all specs, including integration"
task :rspec_all => [:rspec, :rspec_with_integration]

desc 'Alias for rspec'
task :spec => 'rspec'
