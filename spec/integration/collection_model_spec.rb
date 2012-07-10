require 'spec_helper'

# These are integration tests, because we want to exercise 
# the actual solr query to retrieve the Items for a Collection.

describe Hydrus::Collection do
  
  it "should be able to find its member Hydrus::Items" do
    druid = 'druid:oo000oo0003'
    hc    = Hydrus::Collection.find druid
    items = hc.hydrus_items
    druids = items.map { |i| i.pid }
    %w(1 5 6 7).each { |n| druids.should include("druid:oo000oo000#{n}") }
  end

  it "should behave nicely when it has no member Hydrus::Items" do
    druid = 'druid:oo000oo0004'
    hc    = Hydrus::Collection.find druid
    hc.hydrus_items.should == []
  end

end
