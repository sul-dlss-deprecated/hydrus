require 'spec_helper'

describe(Hydrus::Collection, :type => :feature, :integration => true) do

  before(:all) do
    @prev_mint_ids = config_mint_ids()
  end

  after(:all) do
    config_mint_ids(@prev_mint_ids)
  end

  it "should be able to find its member Hydrus::Items" do
    druid = 'druid:oo000oo0003'
    hc    = Hydrus::Collection.find druid
    expect(hc.hydrus_items).to eq(hc.items)
    items = hc.items
    druids = items.map { |i| i.pid }
    expect(druids).to include('druid:oo000oo0001', 'druid:oo000oo0005', 'druid:oo000oo0006', 'druid:oo000oo0007')
  end

  it "should behave nicely when it has no member Hydrus::Items" do
    druid = 'druid:oo000oo0004'
    hc    = Hydrus::Collection.find druid
    expect(hc.hydrus_items).to eq([])
    expect(hc.items).to eq([])
  end

  it "should be able to create a Collection object, with an APO" do
    coll  = Hydrus::Collection.create(mock_authed_user)
    expect(coll).to be_instance_of Hydrus::Collection
    expect(coll).to_not be_new
    expect(coll.apo.roleMetadata.collection_manager.val.first.strip).to include mock_authed_user.sunetid
    expect(coll.item_type).to eq 'collection'
    expect(coll.events.event.val.size).to eq(1)
    expect(coll.events.event.to_a).to include "Collection created"
    expect(coll.object_status).to eq 'draft'
    expect(coll.title).to be_empty
    expect(coll.relationships(:has_model)).to_not include 'info:fedora/afmodel:Dor_Collection'
    expect(coll.relationships(:has_model)).to include 'info:fedora/afmodel:Hydrus_Collection'
  end


end
