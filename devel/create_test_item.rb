def create_test_collection
  # Create a new Collection and set all required values.
  hc          = Hydrus::Collection.create('archivist1')
  hc.title    = hc.pid
  hc.abstract = 'abstract'
  hc.contact  = 'contact'
  hc.requires_human_approval = 'yes'
  # Save and return.
  hc.save
  puts "Created collection: #{hc.pid}"
  return hc
end

def create_test_item
  # Create a new Item and set all required values.
  hc_pid      = ARGV.shift
  hi          = Hydrus::Item.create(hc_pid, 'archivist1')
  hi.title    = hi.pid
  hi.abstract = 'abstract'
  hi.contact  = 'contact'
  hi.accepted_terms_of_deposit = 'yes'
  # Create a file for the Item.
  f       = Hydrus::ObjectFile.new
  f.pid   = hi.pid
  f.label = 'file'
  f.file  = File.open(__FILE__)
  # Save and return.
  f.save
  hi.save
  puts "Created item: #{hi.pid}"
  return hi
end

def main
  obj_type = ARGV.shift
  if %w(item collection).include?(obj_type)
    send("create_test_#{obj_type}")
  else
    puts "Usage: rails runner #{__FILE__} item|collection"
  end
end

main()
