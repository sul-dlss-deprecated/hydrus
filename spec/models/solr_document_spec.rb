require 'spec_helper'

describe SolrDocument do

  it "route_key() should behave as expected" do
    tests = [
      [ 'info:fedora/afmodel:Dor_Collection', 'hydrus_collection'],
      [ 'info:fedora/afmodel:Dor_Item',       'hydrus_item'],
    ]
    tests.each do |has_model_s, exp|
      h = { "#{Solrizer.solr_name("has_model", :symbol)}" => has_model_s }
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
      Solrizer.solr_name("main_title", :displayable)  => 'foo title',
      Solrizer.solr_name('objectId', :symbol) => 'foo:pid',
      Solrizer.solr_name("has_model", :symbol)                 => 'info:fedora/afmodel:Hydrus_Item',
      Solrizer.solr_name("object_status", :displayable)             => 'awaiting_approval',
      Solrizer.solr_name("item_depositor_person_identifier", :displayable) => 'foo_user',
    }
    sdoc = SolrDocument.new h
    sdoc.main_title.should    == 'foo title'
    sdoc.pid.should           == 'foo:pid'
    sdoc.object_type.should   == 'item'
    sdoc.object_status.should == 'waiting for approval'
    sdoc.depositor.should     == 'foo_user'
    sdoc.path.should          == '/items/foo:pid'
  end

end
