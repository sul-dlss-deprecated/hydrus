require 'spec_helper'

describe(Hydrus::Collection, :integration => true) do

  before(:all) do
    @prev_mint_ids = config_mint_ids()
  end

  after(:all) do
    config_mint_ids(@prev_mint_ids)
  end

  it "should be able to find its member Hydrus::Items" do
    druid = 'druid:oo000oo0003'
    hc    = Hydrus::Collection.find druid
    hc.hydrus_items.should == hc.items
    items = hc.items
    druids = items.map { |i| i.pid }
    %w(1 5 6 7).each { |n| druids.should include("druid:oo000oo000#{n}") }
  end

  it "should behave nicely when it has no member Hydrus::Items" do
    druid = 'druid:oo000oo0004'
    hc    = Hydrus::Collection.find druid
    hc.hydrus_items.should == []
    hc.items.should == []
  end

  it "should be able to create a Collection object, with an APO" do
    coll  = Hydrus::Collection.create(mock_authed_user)
    coll.should be_instance_of Hydrus::Collection
    coll.admin_policy_object_ids.should == [coll.apo.pid]
  end

end