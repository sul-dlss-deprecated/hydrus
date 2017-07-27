require 'spec_helper'

describe Hydrus::AdminPolicyObject, :type => :model do

  before(:each) do
    @apo = Hydrus::AdminPolicyObject.new
  end

  describe "class methods" do

    it "should define a license_types hash" do
      expect(Hydrus::AdminPolicyObject.license_types).to be_a Hash
    end

    it "should define an embargo_types hash " do
      expect(Hydrus::AdminPolicyObject.embargo_types).to be_a Hash
    end

    it "should define a visibility_typs hash" do
      expect(Hydrus::AdminPolicyObject.visibility_types).to be_a Hash
    end

    it "should define an embargo_terms hash" do
      expect(Hydrus::AdminPolicyObject.embargo_terms).to be_a Hash
    end

  end

  it "blank-slate APO should include the :pid error" do
    expect(@apo).not_to be_valid
    expect(@apo.errors.messages.keys).to eq([:pid])
  end

end
