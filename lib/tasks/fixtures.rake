namespace :hydrus do

  FIXTURE_PIDS = [
    'druid:oo000oo0000',  # See :helpfix below for info.
    'druid:oo000oo0001',
    'druid:oo000oo0002',
    'druid:oo000oo0003',
    'druid:oo000oo0004',
    'druid:oo000oo0005',
    'druid:oo000oo0006',
    'druid:oo000oo0007',
    'druid:oo000oo0008',
    'druid:oo000oo0009',
    'druid:oo000oo0010',
    'druid:oo000oo0011',
    'druid:oo000oo0012',
    'druid:oo000oo0013',
    'druid:oo000oo0099',    
  ]

  desc "hydrus fixture info"
  task :helpfix do
    puts <<-EOF.gsub(/^ {6}/, '')
      hydrusAssemblyWF: 99
      Ur-APO:           00

      APOs:             02  08  09
      Collections:      03  04  10
      Items:            01      11
                        05      12
                        06      13
                        07
    EOF
  end

  desc "load hydrus fixtures"
  task :loadfix do
    Rake::Task['db:fixtures:load'].invoke
    FIXTURE_PIDS.each { |pid|
      ENV["pid"] = pid
      Rake::Task['repo:load'].reenable
      Rake::Task['repo:load'].invoke
    }
    
    # index the workflow object
    ENV["pid"] = 'druid:oo000oo0099'    
            Rake::Task['hydrus:reindex'].invoke
    
    if !["test","development"].include?(Rails.env) 
      puts "****NOTE: For security reasons, you might want to change passwords for default users after this task using \"RAILS_ENV=#{ENV['RAILS_ENV']}rake hydrus:update_passwords['newpassword']\"*****"
    end
  end

  # call with rake hydrus:reindex pid=druid:oo000oo99
  desc "reindex specified pid"
  task :reindex do 
    require File.expand_path('config/environment')
    pid=ENV["pid"]
    obj = Dor.load_instance pid
    unless obj.nil?
      puts "Reindexing #{pid} in solr"
      solr_doc = obj.to_solr
      Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000})
    else
      puts "#{pid} not found"
    end
  end
  
  # call with hydrus:update_passwords['newpassword']
  desc "update all fixture user passwords"
  task :update_passwords, :new_password do |t,args|
    require File.expand_path('config/environment')
    new_password=args[:new_password]
    users = YAML.load(File.read 'test/fixtures/users.yml')
    users.each do |user,values|
      puts "Updating password for #{values['email']}" 
      u=User.find_by_email(values['email'])
      u.password=new_password
      u.password_confirmation=new_password
      u.save
    end
  end

  # call with rake hydrus:export_object['druid:xx00oo0001','/tmp']
  desc "export object to foxml"
  task :export_object, :pid, :output_dir do |t, args|
    require File.expand_path('config/environment')
    output_dir=args[:output_dir] || File.join(Rails.root.to_s,"tmp")
    pid=args[:pid]
    ActiveFedora::FixtureExporter.export_to_path(pid, output_dir)
  end

  # call with rake hydrus:import_objects['/tmp']
  desc "import foxml objects from directory into dor"
  task :import_objects, :source_dir do |t,args|
    require File.expand_path('config/environment')
    source_dir=args[:source_dir]
    Dir.chdir(source_dir)
    files=Dir.glob('*.foxml.xml')
    files.each do |file|
      pid = ActiveFedora::FixtureLoader.import_to_fedora(File.join(source_dir,file))
      ActiveFedora::FixtureLoader.index(pid)
    end
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
  task :refreshfix => [
    :deletefix,
    :loadfix,
    :refresh_workflows,
    :refresh_upload_files,
  ]

  desc "reload test uploaded files to public/upload directory"
  task :refresh_upload_files do
    # Copies fixture files from source control to the app's public area:
    #   source: spec/fixtures/files/DRUID/*
    #   dest:   public/uploads/DRUID...TREE/content/*
    puts "refreshing upload files"
    app_base = File.expand_path('../../../', __FILE__)
    src_base = File.join(app_base, 'spec/fixtures/files')
    dst_base = File.join(app_base, 'public/uploads')
    FIXTURE_PIDS.each do |pid|
      pid.gsub!('druid:', '')
      src = File.join(src_base, pid)
      dst = DruidTools::Druid.new(pid, dst_base).path('content')
      if File.exists?(src) && File.directory?(src)
        FileUtils.mkdir_p(dst) unless File.directory?(dst)
        cmd = "cp -fr #{src}/* #{dst}/"
        system cmd
      end
    end
  end

  desc "refresh workflow datastreams"
  task :refresh_workflows do
    require File.expand_path('config/environment')
    repo    = 'dor'
    wf_name = 'hydrusAssemblyWF'
    # Read files in workflow fixtures directory.
    Dir.glob("spec/fixtures/workflow_xml/druid_*.xml").each do |f|
      # Read XML from file and get druid from file name.
      xml   = File.read(f)
      druid = File.basename(f, '.xml').gsub(/_/, ':')
      # Push content up to the WF service.
      resp = [druid, wf_name]
      resp << Dor::WorkflowService.delete_workflow(repo, druid, wf_name)
      resp << Dor::WorkflowService.create_workflow(repo, druid, wf_name, xml)
      puts resp.inspect
    end
  end

  desc "restore jetty to initial state"
  task :jetty_nuke do
    puts "Nuking jetty"
    # Restore jetty submodule to initial state.
    Rake::Task['jetty:stop'].invoke
    Dir.chdir('jetty') {
      system('git reset --hard HEAD') or exit
      system('git clean -dfx')        or exit
    }
    Rake::Task['hydra:jetty:config'].invoke
    Rake::Task['jetty:start'].invoke
  end

end
