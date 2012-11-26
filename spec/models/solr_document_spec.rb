require 'spec_helper'

describe SolrDocument do

  it "route_key() should behave as expected" do
    tests = [
      [ 'info:fedora/afmodel:Dor_Collection', 'hydrus_collection'],
      [ 'info:fedora/afmodel:Dor_Item',       'hydrus_item'],
    ]
    tests.each do |has_model_s, exp|
      h = { :has_model_s => has_model_s }
      sdoc = SolrDocument.new h
      sdoc.route_key.should == exp
    end
  end

  it "can exercise to_model(), stubbed" do
    sdoc = SolrDocument.new
    id = 998877
    sdoc.stub(:id).and_return(id)
    ActiveFedora::Base.should_receive(:load_instance_from_solr).with(id, sdoc)
    sdoc.to_model()
  end

  it "can exercise simple getters" do
    h = {
      'main_title_t'                => 'foo title',
      'identityMetadata_objectId_t' => 'foo:pid',
      'has_model_s'                 => 'info:fedora/afmodel:Hydrus_Item',
      'object_status_t'             => 'awaiting_approval',
      "roleMetadata_item_depositor_person_identifier_t" => 'foo_user',
    }
    sdoc = SolrDocument.new h
    sdoc.main_title.should    == h['main_title_t']
    sdoc.pid.should           == h['identityMetadata_objectId_t']
    sdoc.object_type.should   == 'item'
    sdoc.object_status.should == 'waiting for approval'
    sdoc.depositor.should     == 'foo_user'
    sdoc.path.should          == '/items/foo:pid'
  end

end
