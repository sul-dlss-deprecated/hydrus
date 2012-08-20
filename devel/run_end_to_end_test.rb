# This file has the commands needed to run a manual end-to-end object test for a single collection.

# run these commands on a rails console in development mode
collection_druid='druid:qh971sm3987' # the collection druid, it will be exported, along with its apo and associated items
output_dir='/tmp' # output directory to store foxml im

c=Hydrus::Collection.find(collection_druid)
items=c.hydrus_items.collect{|i|i.pid}

druids=[c.pid,c.apo.pid] + items

druids.each do |druid|
  system "rake hydrus:export_object['#{druid}','/tmp']"
end

######################################################################
# now run this command on a unix prompt using the environment you want
RAILS_ENV=test rake hydrus:import_objects['/tmp']
