desc "Stops jetty, runs `rake ci`, and then starts jetty." 

task :local_ci do 
  sub_tasks = %w(jetty:stop db:migrate ci jetty:start)
  sub_tasks.each { |st| Rake::Task[st].invoke }
end
