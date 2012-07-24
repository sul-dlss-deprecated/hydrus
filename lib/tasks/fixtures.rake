namespace :hydrus do
  FIXTURE_PIDS = [
    'druid:oo000oo0000', # The Ur-APO
    'druid:oo000oo0001', # Collection #1: Item #1
    'druid:oo000oo0002', # APO for collecion druid:oo000oo0003
    'druid:oo000oo0003', # Collection #1
    'druid:oo000oo0004', # Collection #2
    'druid:oo000oo0005', # Collection #1: Item #2
    'druid:oo000oo0006', #  "             Item #3
    'druid:oo000oo0007', #  "             Item #4
    'druid:oo000oo0008', # APO for collecion druid:oo000oo0004
  ]


  desc "load hydrus fixtures"
  task :loadfix do
    Rake::Task['db:fixtures:load'].invoke
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
  task :refreshfix => [:deletefix,:loadfix,:refresh_upload_files]
  
  desc "reload test uploaded files to public/upload directory"
  task :refresh_upload_files do
    puts "refreshing upload files"
    app_path=File.expand_path('../../../', __FILE__)
    source_base_path_to_files=File.join(app_path,'spec/fixtures/files')
    dest_base_path_to_files=File.join(app_path,'public/uploads')
    FIXTURE_PIDS.each { |pid|  
      pid.gsub!('druid:','')
      source_path_to_files=File.join(source_base_path_to_files,pid)
      dest_path_to_files=DruidTools::Druid.new(pid,dest_base_path_to_files).path()
      if File.exists?(source_path_to_files) && File.directory?(source_path_to_files)
        FileUtils.mkdir_p(dest_path_to_files) unless File.directory?(dest_path_to_files)
        copy_command="cp -fr #{source_path_to_files}/ #{dest_path_to_files}/"
        system copy_command
      end
    }
  end

  
end
