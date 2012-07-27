require 'spec_helper'

describe Hydrus::GenericObject do

  before(:each) do
    @hi      = Hydrus::GenericObject.new
    @apo_pid = 'druid:oo000oo0002'
  end
  
  it "apo() should return a new blank apo if the apo_pid is nil" do
    @hi.apo.class.should == Hydrus::AdminPolicyObject 
  end

  it "apo() should return fedora object if the apo_pid is defined" do
    mfo = double('mock_fedora_object')
    @hi.apo_pid = @apo_pid
    @hi.stub(:get_fedora_item).and_return mfo
    @hi.apo.should == mfo
  end

  it "apo_pid() should get the correct PID from admin_policy_object_ids()" do
    exp = 'foobar'
    @hi.stub(:admin_policy_object_ids).and_return [exp, 11, 22]
    @hi.should_receive :admin_policy_object_ids
    @hi.apo_pid.should == exp
  end

  it "apo_pid() should get PID directly from @apo_pid when it is defined" do
    exp = 'foobarfubb'
    @hi.apo_pid = exp
    @hi.stub(:admin_policy_object_ids).and_return ['doh', 11, 22]
    @hi.should_not_receive :admin_policy_object_ids
    @hi.apo_pid.should == exp
  end

  it "can exercise discover_access()" do
    @hi.discover_access.should == ""
  end

  it "can exercise object_type()" do
    fake_imd = double('fake_imd', :objectType => [123,456])
    @hi.should_receive(:identityMetadata).and_return(fake_imd)
    @hi.object_type.should == 123
  end

  it "can exercise url()" do
    @hi.url.should == "http://purl.stanford.edu/__DO_NOT_USE__"
  end

  it "can exercise related_items()" do
    ris = @hi.related_items
    ris.size.should == 1
    ri = ris.first
    ri.title.should == ''
    ri.url.should == ''
  end

  describe "registration" do

    it "dor_registration_params() should return the expected hash" do
      # Non-APO: hash should include initiate_workflow. 
      args = %w(whobar item somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      drp.should be_instance_of Hash
      drp[:admin_policy].should == args.last
      drp.should include(:initiate_workflow)
      # APO: hash should not includes initiate_workflow. 
      args = %w(whobar adminPolicy somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      drp.should be_instance_of Hash
      drp.should include(:initiate_workflow)
    end

    it "should be able to exercise register_dor_object(), using stubbed call to Dor" do
      args = %w(whobar item somePID)
      drp = Hydrus::GenericObject.dor_registration_params(*args)
      expectation = Dor::RegistrationService.should_receive(:register_object)
      expectation.with(hash_including(*drp.keys))
      Hydrus::GenericObject.register_dor_object(nil, nil, nil)
    end

  end
  
  describe "class methods" do
    it "should define a licenses hash" do
      Hydrus::GenericObject.licenses.should be_a Hash
    end
    describe "license_commons" do
      it "should define be a hash" do
        Hydrus::GenericObject.license_commons.should be_a Hash
      end
      it "keys should all match license types" do
        Hydrus::GenericObject.license_commons.keys.should == Hydrus::GenericObject.licenses.keys
      end
    end
    it "should have a license_human method that will return a human readible value for a license code" do
      Hydrus::GenericObject.license_human("cc-by").should == "CC BY Attribution"
      Hydrus::GenericObject.license_human("cc-by-nc-sa").should == "CC BY-NC-SA Attribution-NonCommercial-ShareAlike"
      Hydrus::GenericObject.license_human("odc-odbl").should == "ODC-ODbl Open Database License"
    end
  end
end
