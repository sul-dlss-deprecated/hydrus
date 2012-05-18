namespace :hydrus do
  FIXTURE_PIDS = ["druid:ww057vk7675", "druid:sw909tc7852", "druid:oo000oo0001"]
  
  desc "load hydrus fixtures"
  task :loadfix do
    FIXTURE_PIDS.each { |pid|  
      ENV["pid"] = pid
      Rake::Task['repo:load'].reenable
      Rake::Task['repo:load'].invoke
  }
  end
  
  desc "delete hydrus fixtures"
  task :deletefix do
    FIXTURE_PIDS.each { |pid|  
      ENV["pid"] = pid
      Rake::Task['repo:delete'].reenable
      Rake::Task['repo:delete'].invoke
  }
  end
  
  desc "refresh hydrus fixtures"
  task :refreshfix => [:deletefix, :loadfix]
  
end
