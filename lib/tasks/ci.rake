desc 'Run Continuous Integration Suite (tests, coverage, docs)'
task ci: [:rubocop] do
  unless Rails.env.test?
    # force any CI sub-tasks to run in the test environment (e.g. to ensure
    # fixtures get loaded into the right places)
    system('RAILS_ENV=test rake ci')
    next
  end

  Rake::Task['db:migrate'].invoke
  Rake::Task['hydrus:refreshfix'].invoke
  Rake::Task['spec'].invoke
end
