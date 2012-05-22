require 'spec_helper'

describe Hydrus::GenericItem do

  before(:each) do
    @hi      = Hydrus::GenericItem.new
    @dru     = 'druid:oo000oo0001'
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

end
