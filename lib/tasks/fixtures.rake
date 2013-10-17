namespace :hydrus do

  # See lib/hydrus.rb for fixture PIDs.
  require 'hydrus'
  FIXTURE_PIDS = Hydrus.fixture_pids

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
  task :loadfix => ['db:fixtures:load'] do

    fixture_loader = ActiveFedora::FixtureLoader.new('spec/fixtures')
    FIXTURE_PIDS.each { |pid|
      fixture_loader.reload(pid)
    }

    # index the workflow objects
    Rake::Task['hydrus:reindex_workflow_objects'].invoke

    unless ["test","development"].include?(Rails.env)
      puts "****NOTE: For security reasons, you might want to change passwords for default users after this task using \"RAILS_ENV=#{ENV['RAILS_ENV']}rake hydrus:update_passwords['newpassword']\"*****"
    end
  end

  # call with rake hydrus:reindex pid=druid:oo000oo0099
  desc "reindex specified pid"
  task :reindex => :environment do
    pid=ENV["pid"]
    obj = Dor.load_instance pid
    unless obj.nil?
      solr_doc = obj.to_solr
      Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000})
    else
      puts "#{pid} not found"
    end
  end

  # call with rake hydrus:reindex_workflow_objects
  desc "reindex all workflow objects for the given environment"
  task :reindex_workflow_objects => :environment do
    require File.expand_path('config/environment')
    pids=Dor::Config.hydrus.workflow_object_druids
    pids.each do |pid|
      ENV["pid"] = pid
      Rake::Task['hydrus:reindex'].reenable
      Rake::Task['hydrus:reindex'].invoke
    end
  end

  # call with rake hydrus:delete_objects pid=druid:oo000oo0003
  desc "delete a given hydrus collection object and all associated items and APOs"
  task :delete_objects => :environment do
    require File.expand_path('config/environment')
    pid=ENV["pid"]
    collection=Hydrus::Collection.find pid
    unless collection.nil?
      items_pids=collection.items.collect{|item| item.pid}
      all_pids = items_pids << collection.pid << collection.apo.pid
      all_pids.each do |pid|
        puts "Deleteing #{pid}"
        Dor::Config.fedora.client["objects/#{pid}"].delete
        Dor::SearchService.solr.delete_by_id(pid)
        Dor::SearchService.solr.commit
      end
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

  desc "refresh hydrus fixtures"
  task :refreshfix do
    ts = [
      'hydrus:loadfix',
      'hydrus:refresh_workflows',
      'hydrus:refresh_upload_files',
      'hydrus:reindex_workflow_objects',
    ]
    ts.each do |t|
      Rake::Task[t].reenable
      Rake::Task[t].invoke
    end
  end

  desc "reload test uploaded files to public/upload directory"
  task :refresh_upload_files do
    # Copies fixture files from source control to the app's public area:
    #   source: spec/fixtures/files/DRUID/*
    #   dest:   public/uploads/DRUID...TREE/content/*
    puts "refreshing upload files"
    require File.expand_path('config/environment')
    app_base = File.expand_path('../../../', __FILE__)
    src_base = File.join(app_base, 'spec/fixtures/files')
    dst_base = File.join(app_base, 'public',Hydrus::Application.config.file_upload_path)
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

  desc "clear uploaded files [public/upload] directory"
  task :clear_upload_files do
    puts "clearing upload files directory"
    require File.expand_path('config/environment')
    app_base = File.expand_path('../../../', __FILE__)
    dst_base = File.join(app_base, 'public',Hydrus::Application.config.file_upload_path)
    puts "Removing all folders in #{dst_base}"
    all_folders=Dir.glob("#{dst_base}/*")
    all_folders.each do |folder|
       FileUtils.rm_rf folder
    end
  end

  # This task restores the workflows datastream to initial conditions for
  # our fixture objects.
  #   - hydrusAssemblyWF: content is replaces (see spec/fixtures/workflow_xml).
  #   - versioningWF:     content is removed
  # An after() block in spec/integration/item_edit_spec.rb duplications
  # some of this behavior.
  desc "refresh workflow datastreams"
  task :refresh_workflows do
    require File.expand_path('config/environment')
    repo    = 'dor'
    hwf     = 'hydrusAssemblyWF'
    vwf     = 'versioningWF'
    # Read files in workflow fixtures directory.
    Dir.glob("spec/fixtures/workflow_xml/druid_*.xml").each do |f|
      # Read XML from file and get druid from file name.
      xml   = File.read(f)
      druid = File.basename(f, '.xml').gsub(/_/, ':')
      # Push content up to the WF service.
      resp = [druid, hwf]
      resp << Dor::WorkflowService.delete_workflow(repo, druid, hwf)
      resp << Dor::WorkflowService.create_workflow(repo, druid, hwf, xml)
      resp << vwf
      resp << Dor::WorkflowService.delete_workflow(repo, druid, vwf)
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
    Rake::Task['hydrus:clear_upload_files'].invoke
  end

  desc "delete all existing objects in solr without nuking jetty (objects will remain in fedora)"
  task :solr_nuke => :environment do
    require File.expand_path('config/environment')
    url1="curl #{Dor::Config.solrizer.url}/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'"
    url2="curl #{Dor::Config.solrizer.url}/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'"
    puts "Delete all objects at SOLR URL #{Dor::Config.solrizer.url} in Rails environment '#{Rails.env}'? (type yes to proceed)"
    confirm = $stdin.gets.chomp
    if confirm == "yes"
      puts "Nuking solr"
      `#{url1}`
      `#{url2}`
      Rake::Task['hydrus:clear_upload_files'].invoke
    else
      puts "Aborting"
    end
  end

end
