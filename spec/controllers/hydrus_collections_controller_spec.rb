require 'spec_helper'

describe HydrusCollectionsController do

  describe "Index action" do

    it "should redirect with a flash message when we're not dealing w/ a nested resrouce" do
      get :index
      flash[:warning].should =~ /You need to log in/
      response.should redirect_to(new_user_session_path)
    end
  end

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

    it "should route collections/list_all correctly" do
      { :get => "/collections/list_all" }.should route_to(
        :controller => 'hydrus_collections',
        :action     => 'list_all')
    end

    it "custom post actions should route correctly" do
      pid = 'abc123'
      actions = %w(open close)
      actions.each do |a|
        h = { :post => "/collections/#{a}/#{pid}" }
        h.should route_to(:controller => 'hydrus_collections', :action => a, :id => pid)
      end
    end

  end

  describe "Show Action", :integration => true do

    it "should not get fedora document and assign various attributes when not logged in" do
      @pid = 'druid:oo000oo0003'
      controller.stub(:current_user).and_return(mock_user)
      get :show, :id => @pid
      assigns[:fobj].should be_nil
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
      response.should redirect_to(root_path)
      flash[:error].should =~ /You do not have sufficient privileges to edit/
    end

  end

  describe "open/close", :integration => true do

    it "should raise exception if user lacks required permissions" do
      pid = "druid:oo000oo0003"
      err_msg = /\ACannot perform action:/
      controller.stub(:current_user).and_return(mock_user)
      [:open, :close].each do |action|
        e = expect { post(action, :id => pid) }
        e.to raise_exception(err_msg)
      end
    end

  end

  describe "list_all", :integration => true do

    it "should redirect to root url for non-admins when not in development mode" do
      controller.stub(:current_user).and_return(mock_authed_user)
      get(:list_all)
      flash[:error].should =~ /do not have permissions to list all/
      response.should redirect_to(root_path)
    end

    it "should redirect to root path when not logged in" do
      controller.stub(:current_user).and_return(mock_user)
      get(:list_all)
      response.should redirect_to(root_path)
    end

    it "should render the page for users with sufficient powers" do
      controller.stub('can?').and_return(true)
      get(:list_all)
      assigns[:all_collections].should_not == nil
      response.should render_template(:list_all)
    end

  end

end
