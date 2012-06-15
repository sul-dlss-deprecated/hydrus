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

  describe "update action" do
    before(:all) do
      @pid = "druid:oo000oo0003"
    end
    it "should not allow a user to update an object if you do not have edit permissions" do
      controller.stub(:current_user).and_return(mock_user)
      put :update, :id => @pid
      assigns[:document_fedora].should be_nil
      response.should redirect_to hydrus_collection_path(@pid)
      flash[:notice].should =~ /You do not have sufficient privileges to edit this document/
      flash[:notice].should =~ /You have been redirected to the read-only view/
    end
    it "should allow a user to update an object if they do have edit permissions" do
      controller.stub(:current_user).and_return(mock_authed_user)
      put :update, :id => @pid
      assigns[:document_fedora].should_not be_nil
      response.should redirect_to hydrus_collection_path(@pid)
      flash[:notice].should =~ /Your changes have been saved/
    end
  end

end
