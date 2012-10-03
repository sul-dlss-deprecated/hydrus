require 'spec_helper'

describe HydrusCollectionsController do

  describe "Routes and Mapping" do
    
    it "should map collections show correctly" do
      { :get => "/collections/abc" }.should route_to(
        :controller => 'hydrus_collections', 
        :action     => 'show', 
        :id         => 'abc')
    end
    
    it "should map collections destroy_actor action correctly" do
      { :get => "/collections/abc/destroy_actor" }.should route_to(
        :controller => 'hydrus_collections', 
        :action     => 'destroy_actor',
        :id         => 'abc')
    end
    
    it "should have the destroy_hydrus_collection_actor convenience url" do
      destroy_hydrus_collection_actor_path("123").should match(/collections\/123\/destroy_actor/)
    end
    
    it "should map collections destroy_value action correctly" do
      { :get => "/collections/abc/destroy_value" }.should route_to(
        :controller => 'hydrus_collections', 
        :action     => 'destroy_value',
        :id         => 'abc')
    end
    
    it "should have the destroy_hydrus_collection_value convenience url" do
      destroy_hydrus_collection_value_path("123").should match(/collections\/123\/destroy_value/)
    end
    
  end # Routes and Mapping

  describe "Show Action", :integration => true do

    before(:each) do
      @pid = 'druid:oo000oo0003'
    end

    it "should not get fedora document and assign various attributes when not logged in" do
      controller.stub(:current_user).and_return(mock_user)
      get :show, :id => @pid
      assigns[:document_fedora].should be_nil
      response.should redirect_to root_path
    end

  end

  describe "Update Action", :integration => true do

    before(:all) do
      @pid = "druid:oo000oo0003"
    end

    it "should not allow a user to update an object if you do not have edit permissions" do
      controller.stub(:current_user).and_return(mock_user)
      put :update, :id => @pid
      response.should redirect_to hydrus_collection_path(@pid)
      flash[:error].should =~ /You do not have sufficient privileges to edit/
    end

  end

end
