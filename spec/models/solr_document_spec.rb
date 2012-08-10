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

end
