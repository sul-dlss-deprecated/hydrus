require 'spec_helper'

describe Hydrus::GenericObject do

  before(:each) do
    @hi      = Hydrus::GenericObject.new
    @apo_pid = 'druid:oo000oo0002'
  end
  
  it "apo() should return nil if the apo_pid is nil" do
    exp = 'foobar'
    @hi.stub(:admin_policy_object_ids).and_return [nil]
    @hi.apo.should == nil
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

    before(:each) do
      @args = %w(whobar item somePID)
      @drp = Hydrus::GenericObject.dor_registration_params(*@args)
    end

    it "should be able to exercise dor_registration_params() and get a Hash" do
      @drp.should be_kind_of Hash
      @drp[:admin_policy].should == @args.last
      @drp.should include(:source_id)
    end

    it "should be able to exercise register_dor_object(), using stubbed call to Dor" do
      expectation = Dor::RegistrationService.should_receive(:register_object)
      expectation.with(hash_including(*@drp.keys))
      Hydrus::GenericObject.register_dor_object(nil, nil, nil)
    end

  end

end
