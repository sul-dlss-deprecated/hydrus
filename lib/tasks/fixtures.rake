namespace :hydrus do
  # See lib/hydrus.rb for fixture PIDs.
  require 'hydrus'
  FIXTURE_PIDS = Hydrus.fixture_pids

  desc 'hydrus fixture info'
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

  desc 'load hydrus fixtures'
  task loadfix: ['db:fixtures:load'] do
    fixture_loader = ActiveFedora::FixtureLoader.new('spec/fixtures')
    FIXTURE_PIDS.each { |pid|
      fixture_loader.reload(pid)
    }

    unless ['test', 'development'].include?(Rails.env)
      puts "****NOTE: For security reasons, you might want to change passwords for default users after this task using \"RAILS_ENV=#{ENV['RAILS_ENV']}rake hydrus:update_passwords['newpassword']\"*****"
    end
  end

  # call with rake hydrus:reindex pid=druid:oo000oo0099
  desc 'reindex specified pid'
  task reindex: :environment do
    require File.expand_path('config/environment')
    pid = ENV['pid']
    obj = Dor.find pid
    unless obj.nil?
      puts "Reindexing #{pid} in solr"
      solr_doc = obj.to_solr
      ActiveFedora.solr.conn.add(solr_doc, add_attributes: { commitWithin: 1000 })
    else
      puts "#{pid} not found"
    end
  end

  # call with rake hydrus:delete_objects pid=druid:oo000oo0003
  desc 'delete a given hydrus collection object and all associated items and APOs'
  task delete_objects: :environment do
    require File.expand_path('config/environment')
    pid = ENV['pid']
    collection = Hydrus::Collection.find pid
    unless collection.nil?
      items_pids = collection.hydrus_items.collect { |item| item.pid }
      all_pids = items_pids << collection.pid << collection.apo.pid
      all_pids.each do |pid|
        puts "Deleteing #{pid}"
        Dor::Config.fedora.client["objects/#{pid}"].delete
        ActiveFedora.solr.conn.delete_by_id(pid)
        ActiveFedora.solr.conn.commit
      end
    end
  end

  # call with rake hydrus:export_object['druid:xx00oo0001','/tmp']
  desc 'export object to foxml'
  task :export_object, :pid, :output_dir do |t, args|
    require File.expand_path('config/environment')
    output_dir = args[:output_dir] || File.join(Rails.root.to_s, 'tmp')
    pid = args[:pid]
    ActiveFedora::FixtureExporter.export_to_path(pid, output_dir)
  end

  # call with rake hydrus:import_objects['/tmp']
  desc 'import foxml objects from directory into dor'
  task :import_objects, :source_dir do |t, args|
    require File.expand_path('config/environment')
    source_dir = args[:source_dir]
    Dir.chdir(source_dir)
    files = Dir.glob('*.foxml.xml')
    files.each do |file|
      pid = ActiveFedora::FixtureLoader.import_to_fedora(File.join(source_dir, file))
      ActiveFedora::FixtureLoader.index(pid)
    end
  end

  desc 'refresh hydrus fixtures'
  task :refreshfix do
    ts = [
      'hydrus:loadfix',
      'hydrus:refresh_upload_files'
    ]
    ts.each do |t|
      Rake::Task[t].reenable
      Rake::Task[t].invoke
    end
  end

  desc 'reload test uploaded files to public/upload directory'
  task :refresh_upload_files do
    # Copies fixture files from source control to the app's public area:
    #   source: spec/fixtures/files/DRUID/*
    #   dest:   public/uploads/DRUID...TREE/content/*
    puts 'refreshing upload files'
    require File.expand_path('config/environment')
    app_base = File.expand_path('../../../', __FILE__)
    src_base = File.join(app_base, 'spec/fixtures/files')
    dst_base = File.join(app_base, 'public', Hydrus::Application.config.file_upload_path)
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

  desc 'clear uploaded files [public/upload] directory'
  task :clear_upload_files do
    puts 'clearing upload files directory'
    require File.expand_path('config/environment')
    app_base = File.expand_path('../../../', __FILE__)
    dst_base = File.join(app_base, 'public', Hydrus::Application.config.file_upload_path)
    puts "Removing all folders in #{dst_base}"
    all_folders = Dir.glob("#{dst_base}/*")
    all_folders.each do |folder|
      FileUtils.rm_rf folder
    end
  end

  desc 'delete all existing objects in solr without nuking objects in fedora'
  task solr_nuke: :environment do
    require File.expand_path('config/environment')
    url1 = "curl #{Dor::Config.solrizer.url}/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'"
    url2 = "curl #{Dor::Config.solrizer.url}/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'"
    puts "Delete all objects at SOLR URL #{Dor::Config.solrizer.url} in Rails environment '#{Rails.env}'? (type yes to proceed)"
    confirm = $stdin.gets.chomp
    if confirm == 'yes'
      puts 'Nuking solr'
      `#{url1}`
      `#{url2}`
      Rake::Task['hydrus:clear_upload_files'].invoke
    else
      puts 'Aborting'
    end
  end
end
