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
      response.should redirect_to new_user_session_path
    end

  end

  describe "update action" do
    before(:all) do
      @pid = "druid:oo000oo0003"
    end
    it "should not allow a user to update an object if you do not have edit permissions" do
      controller.stub(:current_user).and_return(mock_user)
      put :update, :id => @pid
      response.should redirect_to hydrus_collection_path(@pid)
      flash[:alert].should =~ /You do not have sufficient privileges to edit this document/
      flash[:alert].should =~ /You have been redirected to the read-only view/
    end
    it "should allow a user to update an object if they do have edit permissions" do
      controller.stub(:current_user).and_return(mock_authed_user)
      put :update, :id => @pid
      assigns[:document_fedora].should_not be_nil
      response.should redirect_to hydrus_collection_path(@pid)
      flash[:notice].should =~ /Your changes have been saved/
    end
  end

  it "should be able to create an APO object, whose APO is the Ur-APO" do
    apo = controller.send(:create_apo, 'foo@bar.com')
    apo.should be_kind_of Dor::AdminPolicyObject
    apo.admin_policy_object_ids.first.should == Dor::Config.ur_apo_druid
  end

end
