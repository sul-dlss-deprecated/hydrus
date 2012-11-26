require 'spec_helper'

describe SigninController do

  describe "routes" do
    it "should properly define login" do
      webauth_login_path.should == "/users/auth/webauth"
      assert_routing({ :path => "users/auth/webauth", :method => :get },
        { :controller => "signin", :action => "login" })
    end
    it "should properly define logout" do
      webauth_logout_path.should == "/users/auth/webauth/logout"
      assert_routing({ :path => "users/auth/webauth/logout", :method => :get },
        { :controller => "signin", :action => "logout" })
    end
  end

  describe "login" do
    it "should redirect to the referrer passed in the URL" do
      get :login, :referrer => "/somepath"
      response.should redirect_to("/somepath")
    end
  end

  describe "logout" do
    before(:each) do
      request.env["HTTP_REFERER"] = "/somepath"
    end
    it "should set the flash message letting the user know they have been logged out" do
      get :logout
      flash[:notice].should == "You have successfully logged out of WebAuth."
      response.should redirect_to("/")
    end
    it "should not set the flash message if the user is still logged into WebAuth." do
      request.env["WEBAUTH_USER"] = "not-a-real-user"
      get :logout
      flash[:notice].should be_nil
      response.should redirect_to("/")
    end
    it "should redirect back to home page after logout" do
      get :logout
      response.should redirect_to("/")
    end
  end

end