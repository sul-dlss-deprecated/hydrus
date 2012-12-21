require 'spec_helper'

describe Hydrus::AdminPolicyObject do

  before(:each) do
    @apo = Hydrus::AdminPolicyObject.new
  end

  it "can exercise a stubbed version of create()" do
    # More substantive testing is done at integration level.
    druid = 'druid:BLAH'
    stubs = [
      :remove_relationship,
      :assert_content_model,
      :save,
    ]
    stubs.each { |s| @apo.should_receive(s) }
    @apo.stub(:pid).and_return(druid)
    @apo.stub(:adapt_to).and_return(@apo)
    Hydrus::GenericObject.stub(:register_dor_object).and_return(@apo)
    @apo.title.should == ''
    @apo.roleMetadata.find_by_xpath('//role').size.should == 0
    Hydrus::AdminPolicyObject.create('USERFOO').pid.should == druid
    @apo.title.should == Dor::Config.hydrus.initial_apo_title
    role_nodes = @apo.roleMetadata.find_by_xpath('//role')
    role_nodes.size.should == 2
    role_nodes[0]['type'].should == 'hydrus-collection-manager'
    role_nodes[1]['type'].should == 'hydrus-collection-depositor'
    ra_regex = /<hydra:referencesAgreement[^>]+druid:mc322hh4254"\/>/x
    @apo.rels_ext.to_rels_ext.should =~ ra_regex
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
