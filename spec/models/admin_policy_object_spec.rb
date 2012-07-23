require 'spec_helper'

describe Hydrus::AdminPolicyObject do
  describe "roles" do
    it "should have a default role of item-depositor" do
      Hydrus::AdminPolicyObject.default_role.should == "item-depositor"
    end
    it "should have an array of possible roles" do
      Hydrus::AdminPolicyObject.roles.should be_a Array
    end
  end
end