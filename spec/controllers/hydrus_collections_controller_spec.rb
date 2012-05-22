require 'spec_helper'

describe HydrusCollectionsController do

  describe "show action" do

    before(:each) do
      @pid = 'druid:oo000oo0003'
    end

    it "should not get fedora document and assign various attributes when not logged in", :integration => true do
      controller.stub(:current_user).and_return(mock_user)
      get :show, :id => @pid
      assigns[:document_fedora].should be_nil
      response.should redirect_to :hydrus_collections
    end

  end

end
