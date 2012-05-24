#!/usr/bin/env ruby

# A script for use IRB-style experimentation, using a script.
#
#   rails runner script/experiment.rb


hi   = Hydrus::Item.find('druid:oo000oo0001')
dmd  = hi.descMetadata
cmd  = hi.contentMetadata
rm   = hi.rightsMetadata
coll = hi.collection
wf   = hi.workflows

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

