require 'spec_helper'

describe User do

  before(:each) do
    @id    = 'somebody'
    @email = "#{@id}@example.com"
    @u     = User.create(:email => @email)
  end

  it "should return false to is_webauth?" do
    @u.is_webauth?.should be_false
  end

  it "to_s() should return the user ID portion of the email" do
    @u.to_s.should == @id
  end

end
