require 'spec_helper'

describe User do
  it "should return false to is_webauth?" do
    User.create(:email=>"some-email@example.com").is_webauth?.should be_false
  end
end
