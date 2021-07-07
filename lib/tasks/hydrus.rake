namespace :hydrus do
  desc 'associate DOR item with Hydrus'
  # associates a non-hydrus DOR item with the Hydrus app by adding datastreams and indexing into Hydrus solr
  # need to pass in druid of object to associated, collection druid of Hydrus collection to associate with, and type of hydrus object (e.g. dataset)
  # run with RAILS_ENV=production rake hydrus:index_object druid=druid:bb123bb1234 collection=druid:oo00oo002 type=dataset
  task index_object: :environment do |t, args|
    druid = ENV['druid'] # druid to index (full druid, including druid: prefix)
    collection = ENV['collection'] # druid of collection to associate with  (full druid, including druid: prefix)
    item_type = ENV['type'] # type of hydrus item

    item = Hydrus::Item.find(druid) # get druid

    coll = Hydrus::Collection.find(collection)

    # Add the Item to the Collection.
    item.collections << coll

    # change item type in RELS-EXT to be a hydrus item
    item.datastreams['RELS-EXT'].content.gsub!('<fedora-model:hasModel rdf:resource="info:fedora/afmodel:Dor_Item"></fedora-model:hasModel>', '<fedora-model:hasModel rdf:resource="info:fedora/afmodel:Hydrus_Item"/>')
    item.remove_relationship :has_model, 'info:fedora/afmodel:Dor_Item'
    item.assert_content_model

    # ruby black magic: redefine should_validate and another method so we can save this hydrus item without going through all of the UI validations
    item.define_singleton_method :should_validate, lambda { false }
    item.define_singleton_method :check_version_if_license_changed, lambda { return }

    # create hydrusProperties datastream and set values
    item.item_type = item_type
    item.accepted_terms_of_deposit = 'true'
    item.reviewed_release_settings = 'true'
    item.hydrusProperties.requires_human_approval = 'false'
    item.object_status = 'published'
    item.hydrusProperties.last_modify_time = Time.now.to_s
    item.hydrusProperties.submit_for_approval_time = Time.now.to_s
    item.hydrusProperties.initial_publish_time = Time.now.to_s
    item.hydrusProperties.initial_submitted_for_publish_time = Time.now.to_s
    item.hydrusProperties.submitted_for_publish_time = Time.now.to_s

    # save item
    item.save

    # index into solr
    solr = ActiveFedora.solr.conn
    solr_doc = item.to_solr
    solr.add(solr_doc, add_attributes: { commitWithin: 5000 })
  end

  desc 'Index all DOR defined workflow objects into Hydrus solr instance'
  task index_all_workflows: :environment do
    # get all workflow objects using risearch (sparql on fedora) since we don't have a direct connection to argo solr
    model_type = "<#{Dor::WorkflowObject.to_class_uri}>"
    solr = ActiveFedora.solr.conn
    pids = Dor::SearchService.risearch 'select $object from <#ri> where $object ' "<fedora-model:hasModel> #{model_type}", { limit: nil }
    pids.each { |pid| solr.add(Dor.find(pid).to_solr, add_attributes: { commitWithin: 5000 }) } # index into hydrus solr
  end

  desc 'Reindex all hydrus collections and items into hydrus solr'
  task reindex_all_hydrus_objects: :environment do
    solr = ActiveFedora.solr.conn
    collection_pids = Hydrus::Collection.all_hydrus_collections
    total_collections = collection_pids.size
    puts "Found #{total_collections} hydrus collections.  Started re-index at #{Time.now}"
    collection_pids.each_with_index do |collection_pid, coll_index|
      puts "#{coll_index + 1} of #{total_collections}: Collection #{collection_pid}"
      collection = Hydrus::Collection.find(collection_pid)
      solr.add(collection.to_solr, add_attributes: { commitWithin: 5000 })
      total_items = collection.items.size
      collection.items.each_with_index do |item, item_index|
        puts "....#{item_index + 1} of #{total_items}: Item #{item.pid}"
        solr.add(item.to_solr, add_attributes: { commitWithin: 5000 })
      end
    end
    puts "Completed re-index at #{Time.now}"
  end

  desc 'Cleanup file upload temp files'
  task cleanup_tmp: :environment do
    CarrierWave.clean_cached_files!
  end

  desc 'add person to collection manager'
  task :add_to_collection_manager, [:sunetid] => :environment do |_t, args|
    new_sunet = args[:sunetid]
    logger = Logger.new("#{Rails.root}/log/add_to_collection_manager.log")
    druids = CSV.read('tmp/add.txt').flatten
    total_druids = druids.count
    druids.each_with_index do |druid, i|
      message = "#{i + 1} of #{total_druids} : #{druid}"
      puts message
      fobj = Hydrus::Collection.find("druid:#{druid}")
      if fobj.apo.class != Hydrus::AdminPolicyObject || fobj.object_type != 'collection'
        message = "....SKIPPING #{druid}, not a valid hydrus collection object"
        logger.error message
        puts message
        next
      end
      unless fobj.valid?
        message = "....SKIPPING #{druid}, not able to save (likely in a draft state)"
        logger.error message
        puts message
        next
      end
      if fobj.apo_person_roles['hydrus-collection-manager']&.include? new_sunet
        message = "....SKIPPING #{druid}, already has #{new_sunet}"
        logger.error message
        puts message
        next
      end
      message = ".....ADDING to #{druid}: #{new_sunet}"
      logger.info message
      puts message
      collection_managers = fobj.cleaned_usernames['hydrus-collection-manager']&.split(',') || []
      fobj.apo_person_roles = fobj.cleaned_usernames.merge({ 'hydrus-collection-manager' => collection_managers.push(new_sunet).join(',') })
      fobj.save
    end
  end
end

desc 'rails server with suppressed output'
task server: :environment do
  # Note: to get this to work nicely, we also set the app to generate
  # unbuffered output: see config/application.rb.
  exclusions = [
    'WARN  Could not determine content-length of response',
    '^Loaded datastream druid:',
    '^Loaded datastream list',
    '^Solr response: '
  ]
  regex = exclusions.join('|')
  cmd = [
    'rails server 2>&1',
    %Q<ruby -ne 'BEGIN { STDOUT.sync = true }; print $_ unless $_ =~ /#{regex}/'>
  ].join(' | ')
  system(cmd)
end
