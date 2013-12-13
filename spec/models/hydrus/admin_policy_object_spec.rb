require 'spec_helper'

describe Hydrus::AdminPolicyObject do

  before(:each) do
    @apo = Hydrus::AdminPolicyObject.new
  end

  describe "class methods" do

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

  it "blank-slate APO should include the :pid error" do
    @apo.valid?.should == false
    @apo.errors.messages.keys.should == [:pid]
  end

end
