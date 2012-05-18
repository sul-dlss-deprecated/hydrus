require 'spec_helper'

describe HydrusCollectionsController do

  describe "show action" do

    before(:each) do
      @pid = 'druid:oo000oo0003'
    end

    it "should get fedora document and assign various attributes", :integration => true do
      get :show, :id => @pid
      assigns[:document_fedora].should_not be_nil
    end

  end

end
