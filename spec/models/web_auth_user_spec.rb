require 'spec_helper'

describe WebAuthUser do
  describe "w/ webauth user" do
    before(:each) do
      @user = WebAuthUser.new("jdoe")
    end
    it "should respond to to_s w/ the user ID" do
      @user.to_s.should == "jdoe"
    end
    it "should respond to sunetid w/ the user ID" do
      @user.sunetid.should == "jdoe"
    end    
    it "should respond to email w/ the user ID + @stanford.edu" do
      @user.email.should == "jdoe@stanford.edu"
    end
    it "should return true to is_webauth?" do
      @user.is_webauth?.should be_true
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
