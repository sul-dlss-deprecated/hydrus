require 'spec_helper'

describe Hydrus::AdminPolicyObject do

  before(:each) do
    @apo = Hydrus::AdminPolicyObject.new
  end

  describe "class methods" do

    describe "roles" do

      it "should have a default role of hydrus-item-depositor" do
        Hydrus::AdminPolicyObject.default_role.should == "hydrus-item-depositor"
      end

      it "should have a hash of possible roles" do
        Hydrus::AdminPolicyObject.roles.should be_a Hash
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

  describe "validations" do

    before(:each) do
      @exp = [:pid, :embargo, :license, :embargo_option, :license_option]
    end

    it "blank slate APO (should_validate=false) should include only the :pid error" do
      @apo.stub(:should_validate).and_return(false)
      @apo.valid?.should == false
      @apo.errors.messages.keys.should == [@exp.first]
    end

    it "blank slate APO (open) should include all validation errors" do
      @apo.stub(:should_validate).and_return(true)
      @apo.valid?.should == false
      @apo.errors.messages.keys.should include(*@exp)
    end

    it "fully populated APO should be valid" do
      @apo.stub(:should_validate).and_return(true)
      dru = 'druid:ll000ll0001'
      @exp.each { |e| @apo.stub(e).and_return(dru) }
      @apo.valid?.should == true
    end

  end

end
