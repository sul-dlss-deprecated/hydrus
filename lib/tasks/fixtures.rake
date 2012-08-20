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
  ]

  desc "hydrus fixture info"
  task :helpfix do
    puts <<-EOF.gsub(/^ {6}/, '')
      Ur-APO:       00
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
  end

  # call with rake hydrus:export_object['druid:xx00oo0001','/tmp']
  desc "export object to foxml"
  task :export_object, :pid, :output_dir do |t, args|
    require File.expand_path('config/environments/overrides')
    output_dir=args[:output_dir] || File.join(Rails.root.to_s,"tmp")
    pid=args[:pid]
    ActiveFedora::FixtureExporter.export_to_path(pid, output_dir)  
  end

  # call with rake hydrus:import_objects['/tmp']
  desc "import foxml objects from directory into dor"
  task :import_objects, :source_dir do |t,args|
    require File.expand_path('config/environments/overrides')
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
    puts "refreshing upload files"
    app_path=File.expand_path('../../../', __FILE__)
    source_base_path_to_files=File.join(app_path,'spec/fixtures/files')
    dest_base_path_to_files=File.join(app_path,'public/uploads')
    FIXTURE_PIDS.each { |pid|
      pid.gsub!('druid:','')
      source_path_to_files=File.join(source_base_path_to_files,pid)
      dest_path_to_files=DruidTools::Druid.new(pid,dest_base_path_to_files).path('content')
      if File.exists?(source_path_to_files) && File.directory?(source_path_to_files)
        FileUtils.mkdir_p(dest_path_to_files) unless File.directory?(dest_path_to_files)
        copy_command="cp -fr #{source_path_to_files}/* #{dest_path_to_files}/"
        system copy_command
      end
    }
  end

  desc "refresh workflow datastreams"
  task :refresh_workflows do
    require File.expand_path('config/environments/overrides')
    repo    = 'dor'
    wf_name = 'hydrusAssemblyWF'
    steps   = [
      ['start-deposit', ' status="completed" lifecycle="registered"'],
      ['submit', ''],
      ['approve', ''],
      ['start-assembly', ''],
    ]
    FIXTURE_PIDS.each { |druid|
      resp = [druid, wf_name]
      resp << Dor::WorkflowService.delete_workflow(repo, druid, wf_name)
      xml  = steps.map { |step, extra| %Q(<process name="#{step}"#{extra}/>) }.join ''
      xml  = "<workflow>#{xml}</workflow>"
      resp << Dor::WorkflowService.create_workflow(repo, druid, wf_name, xml)
      puts resp.inspect
    }
  end

end
