require 'spec_helper'

describe Hydrus::AdminPolicyObject do
  describe "class methods" do
    describe "roles" do
      it "should have a default role of item-depositor" do
        Hydrus::AdminPolicyObject.default_role.should == "item-depositor"
      end
      it "should have an array of possible roles" do
        Hydrus::AdminPolicyObject.roles.should be_a Array
      end
    end
    it "should define a license_types hash" do
      Hydrus::AdminPolicyObject.license_types.should be_a Hash
    end
    it "should define an embargo_types hash " do
      Hydrus::AdminPolicyObject.embargo_types.should be_a Hash
    end
    it "should define a visibility_typs hash" do
      Hydrus::AdminPolicyObject.visibility_types.should be_a Hash
    end
    it "should define an embargo_terms hash" do
      Hydrus::AdminPolicyObject.embargo_terms.should be_a Hash
    end
  end  
end