#!/usr/bin/env ruby

# A script for IRB-style experimentation, using a script.
# Run it like this:
#
#   rails runner script/experiment.rb


hi   = Hydrus::Item.find('druid:oo000oo0001')
dmd  = hi.descMetadata
cmd  = hi.contentMetadata
rm   = hi.rightsMetadata
coll = hi.collection
wf   = hi.workflows

__END__

[2,3].each do |n|
  pid = "druid:oo000oo000#{n}"
  uri = "info:fedora/#{pid}"
  hi.add_relationship_by_name 'set',        uri
  hi.add_relationship_by_name 'collection', uri
end

ap hi.relationships(:is_member_of)
ap hi.relationships(:is_member_of_collection)

[2,3].each do |n|
  pid = "druid:oo000oo000#{n}"
  uri = "info:fedora/#{pid}"
  hi.remove_relationship_by_name 'set',        uri
  hi.remove_relationship_by_name 'collection', uri
end

ap hi.relationships(:is_member_of)
ap hi.relationships(:is_member_of_collection)


__END__

hi.add_to_collection 'druid:oo000oo0002'
hi.save

c = Hydrus::Item.find('druid:oo000oo0002')
hi.add_relationship_by_name 'set',        c
hi.add_relationship_by_name 'collection', c
hi.save

__END__

file_nodes = cmd.ng_xml.xpath '//file'

file_nodes.each do |fn|
  ap fn['id']
end

__END__


blk = lambda { |xml|
  xml.relatedItem {
    xml.titleInfo { xml.title }
    xml.identifier(:type=>"uri")
  }
}

builder = Nokogiri::XML::Builder.new(&blk)
node = builder.doc.root
puts node

__END__

