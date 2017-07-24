require 'spec_helper'

describe SolrDocument, :type => :model do

  it "route_key() should behave as expected" do
    tests = [
      [ 'info:fedora/afmodel:Dor_Collection', 'hydrus_collection'],
      [ 'info:fedora/afmodel:Dor_Item',       'hydrus_item'],
    ]
    tests.each do |has_model_ssim, exp|
      h = { :has_model_ssim => has_model_ssim }
      sdoc = SolrDocument.new h
      expect(sdoc.route_key).to eq(exp)
    end
  end

  it "can exercise to_model(), stubbed" do
    sdoc = SolrDocument.new
    id = 998877
    allow(sdoc).to receive(:id).and_return(id)
    expect(ActiveFedora::Base).to receive(:load_instance_from_solr).with(id, sdoc)
    sdoc.to_model()
  end

  it "can exercise simple getters" do
    h = {
      'main_title_ssm'                => 'foo title',
      'objectId_ssim' => 'foo:pid',
      'has_model_ssim'                 => 'info:fedora/afmodel:Hydrus_Item',
      'object_status_sim'             => 'awaiting_approval',
      "item_depositor_person_identifier_ssm" => 'foo_user',
    }
    sdoc = SolrDocument.new h
    expect(sdoc.main_title).to    eq(h['main_title_ssm'])
    expect(sdoc.pid).to           eq(h['objectId_ssim'])
    expect(sdoc.object_type).to   eq('item')
    expect(sdoc.object_status).to eq('waiting for approval')
    expect(sdoc.depositor).to     eq('foo_user')
    expect(sdoc.path).to          eq('/items/foo:pid')
  end

end
