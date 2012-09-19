require 'spec_helper'

describe(Hydrus::GenericObject, :integration => true) do
 
  before(:each) do
    @prev_mint_ids = config_mint_ids()
  end

  after(:each) do
    config_mint_ids(@prev_mint_ids)
  end

  describe "approve()" do
    
    it "should modify workflows as expected" do
      # Setup.
      druid = 'druid:oo000oo0003'
      hi    = Hydrus::Item.create(druid, 'user_foo')
      wf    = Dor::Config.hydrus.app_workflow
      steps = Dor::Config.hydrus.workflow_steps[wf].map { |s| s[:name] }
      exp   = Hash[ steps.map { |s| [s, 'waiting'] } ]
      # Code to check workflow statuses.
      check_statuses = lambda {
        hi = Hydrus::Item.find(hi.pid)  # A refreshed copy of object.
        statuses = steps.map { |s| [s, hi.get_workflow_status(s)] }
        Hash[statuses].should == exp
      }
      # Initial statuses.
      exp['start-deposit'] = 'completed'
      check_statuses.call()
      # After approval (with start_common_assembly=false).
      hi.stub(:should_start_common_assembly).and_return(false)
      hi.approve()
      exp['approve'] = 'completed'
      check_statuses.call()
      # After approval (with start_common_assembly=true).
      hi.stub(:should_start_common_assembly).and_return(true)
      hi.should_receive(:initiate_apo_workflow).once
      hi.approve()
      exp['start-assembly'] = 'completed'
      check_statuses.call()
    end

  end

end
