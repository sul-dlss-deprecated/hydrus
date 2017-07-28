require 'spec_helper'

describe WebAuthUser, type: :model do
  describe "w/ webauth user" do
    before(:each) do
      @user = WebAuthUser.new("jdoe")
    end
    it "should respond to to_s w/ the user ID" do
      expect(@user.to_s).to eq("jdoe")
    end
    it "should respond to sunetid w/ the user ID" do
      expect(@user.sunetid).to eq("jdoe")
    end
    it "should respond to email w/ the user ID + @stanford.edu" do
      expect(@user.email).to eq("jdoe@stanford.edu")
    end
    it "should return true to is_webauth?" do
      expect(@user.is_webauth?).to be_truthy
    end
  end
  
  describe "Privilege Groups" do
    let(:user_without_a_group) { WebAuthUser.new("jdoe") }
    let(:user_in_the_admin_group) { WebAuthUser.new("jdoe", { "WEBAUTH_LDAPPRIVGROUP" => "dlss:hydrus-app-administrators"})}
    let(:user_in_role_groups) {  WebAuthUser.new("jdoe", { "WEBAUTH_LDAPPRIVGROUP" => "dlss:hydrus-app-collection-creators|dlss:hydrus-app-global-viewers"}) }
    it "should have no privileges by default" do
      expect(user_without_a_group.is_administrator?).to be_falsey
      expect(user_without_a_group.is_collection_creator?).to be_falsey
      expect(user_without_a_group.is_global_viewer?).to be_falsey
    end
    
    it "should have privileges if the user is in the admin group" do
      expect(user_in_the_admin_group.is_administrator?).to be_truthy
      expect(user_in_the_admin_group.is_collection_creator?).to be_truthy
      expect(user_in_the_admin_group.is_global_viewer?).to be_truthy
    end
    
    it "should have privileges if the user is part of a priv group" do
      expect(user_in_role_groups.is_administrator?).to be_falsey
      expect(user_in_role_groups.is_collection_creator?).to be_truthy
      expect(user_in_role_groups.is_global_viewer?).to be_truthy
    end
  end

  describe "w/o enviornment variable set" do
    it "should raise an error" do
      expect{WebAuthUser.new("")}.to raise_error
      expect{WebAuthUser.new(nil)}.to raise_error
      expect{WebAuthUser.new}.to raise_error
    end
  end
end
