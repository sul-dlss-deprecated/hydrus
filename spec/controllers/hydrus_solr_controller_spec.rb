require 'spec_helper'

# Note: other behavior is exercised in integration tests.

describe HydrusSolrController do

  describe "reindex()" do

    it "should respond with 404 if object is not in Fedora" do
      bogus_pid = 'druid:BLAH'
      ActiveFedora::Base.stub(:find).and_return(nil)
      get :reindex, :id => bogus_pid
      response.status.should == 404
      response.body.should include("failed to find object")
    end

    it "should skip non-Hydrus objects" do
      some_pid = 'druid:oo000oo9999'
      ActiveFedora::Base.stub(:find).and_return(Object.new)
      get(:reindex, :id => some_pid)
      response.status.should == 200
      response.body.should include("skipped")
    end
    
  end

end
