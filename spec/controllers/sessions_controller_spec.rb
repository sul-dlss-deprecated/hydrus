require 'spec_helper'

describe SessionsController do

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "routes" do
    it "should properly define login" do
      pending
      webauth_login_path.should == "/users/auth/webauth"
      assert_routing({ :path => "users/auth/webauth", :method => :get },
        { :controller => "sessions", :action => "new" })
    end
    it "should properly define logout" do
      webauth_logout_path.should == "/users/auth/webauth/logout"
      assert_routing({ :path => "users/auth/webauth/logout", :method => :get },
        { :controller => "sessions", :action => "destroy_webauth" })
    end
  end

  describe "destroy_webauth" do
    before(:each) do
      request.env["HTTP_REFERER"] = "/somepath"
    end
    it "should set the flash message letting the user know they have been logged out" do
      get :destroy_webauth
      flash[:notice].should == "You have successfully logged out of WebAuth."
      response.should redirect_to("/")
    end
    it "should not set the flash message if the user is still logged into WebAuth." do
      request.env["WEBAUTH_USER"] = "not-a-real-user"
      get :destroy_webauth
      flash[:notice].should be_nil
      response.should redirect_to("/")
    end
    it "should redirect back to home page after logout" do
      get :destroy_webauth
      response.should redirect_to("/")
    end
  end

end