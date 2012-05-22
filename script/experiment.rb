#!/usr/bin/env ruby

# A script for use IRB-style experimentation, using a script.
#
#   rails runner script/experiment.rb


__END__

hi   = Hydrus::Item.find('druid:oo000oo0001')
dmd  = hi.descMetadata
cmd  = hi.contentMetadata
rm   = hi.rightsMetadata
coll = hi.collection
