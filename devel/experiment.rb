#!/usr/bin/env ruby

# A script for IRB-style experimentation, using a script.
#
# To run as an ordinary script:
#
#   rails runner script/experiment.rb
#
# To launch IRB, using the context of the script:
#
#   rails runner devel/experiment.rb --irb
#   >> cb $MB        # Set the binding.
#   >> puts hi.pid

USE_IRB = ARGV.delete '--irb'

dru = 'druid:bb123bb1234'
hi  = Hydrus::Item.find(dru)
hc  = hi.collection

dmd = hi.descMetadata
cmd = hi.contentMetadata
rm  = hi.rightsMetadata
hp  = hi.hydrusProperties
vm  = hi.versionMetadata
wf  = hi.workflows
hc  = hi.collection
apo = hc.apo

if USE_IRB
  require 'irb'
  $MB = binding
  IRB.start(__FILE__)
end

hc.apo.dc.title = ['blah']
hc.apo.dc.content_will_change!
hc.save_apo

[hi, hc].each do |obj|
  nd = obj.rightsMetadata.use.machine.nodeset.first
  nd.content = 'cc-by'

  hp = obj.hydrusProperties.ng_xml
  node_mapping = {
    'submittedForPublishTime'        => 'publishTime',
    'initialSubmittedForPublishTime' => 'initialPublishTime',
  }
  node_mapping.each do |old_name, new_name|
    old_node = hp.at_xpath('//' + old_name)
    txt = old_node.content
    old_node.remove
    new_node = Nokogiri::XML::Node.new new_name, hp
    new_node.content = txt
    hp.root.add_child(new_node)
  end

  obj.rightsMetadata.content_will_change!
  obj.hydrusProperties.content_will_change!
  obj.save
end

__END__

dmd.insert_related_item

hi.related_item_title = {"0"=>"aaaa", "1"=>"bbbb"}
hi.related_item_url   = {"0"=>"aaaa", "1"=>"bbbb"}

puts dmd.ng_xml

__END__

# ns = "http://projecthydra.org/ns/relations#"
# ActiveFedora::Predicates.predicate_mappings[ns][:references_agreement] = 'referencesAgreement'

# Add this to dor-services
# :references_agreement: referencesAgreement

apo = hi.apo
uri = "info:fedora/druid:mc322hh4254"
apo.add_relationship(:references_agreement, uri)
puts apo.rels_ext.to_rels_ext

__END__

puts hi.descMetadata.ng_xml
puts [hi.title, hi.collection.title].inspect
puts hi.generate_dublin_core

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

hi.add_to_collection 'druid:bb000bb0002'
hi.save

c = Hydrus::Item.find('druid:bb000bb0002')
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
