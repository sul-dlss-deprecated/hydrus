require 'rspec/core/rake_task'

desc "Run all specs"
RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
end

desc 'Alias for rspec'
task :spec => 'rspec'

