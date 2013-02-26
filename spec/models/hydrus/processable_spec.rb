require 'spec_helper'

describe Hydrus::Processable do

  before(:each) do
    @cannot_do_regex = /\ACannot perform action/
    @go = Hydrus::GenericObject.new
  end

  describe "complete_workflow_step()" do

    it "can exercise the method, stubbing out call to WF service" do
      step = 'submit'
      args = ['dor', @go.pid, kind_of(Symbol), step, 'completed']
      Dor::WorkflowService.should_receive(:update_workflow_status).with(*args)
      @go.stub_chain(:workflows, :workflow_step_is_done).and_return(false)
      @go.should_receive(:workflows_content_is_stale)
      @go.complete_workflow_step(step)
    end

  end

  it "can exercise uncomplete_workflow_steps() stubbed" do
    @go.should_receive(:update_workflow_status).exactly(3).times
    @go.uncomplete_workflow_steps()
  end

  it "can exercise workflows_content_is_stale, stubbed" do
    @go.workflows.should_receive(:instance_variable_set).twice
    @go.workflows_content_is_stale
  end

  describe "start_common_assembly()" do

    it "should raise exception if the object is not assemblable" do
      @go.stub(:is_assemblable).and_return(false)
      expect { @go.start_common_assembly }.to raise_exception(@cannot_do_regex)
    end

    it "can exercise the method, stubbed" do
      @go.stub(:is_assemblable).and_return(true)
      @go.should_receive(:update_content_metadata).once
      @go.should_receive(:complete_workflow_step).once
      @go.should_receive(:start_assembly_wf).once
      @go.start_common_assembly
    end

  end

  describe "start_assembly_wf()" do

    it "should do nothing if the app is not configured to start assemblyWF" do
      @go.stub(:should_start_assembly_wf).and_return(false)
      Dor::WorkflowService.should_not_receive(:create_workflow)
      @go.start_assembly_wf
    end

    it "can exercise should_start_assembly_wf()" do
      @go.should_start_assembly_wf.should == Dor::Config.hydrus.start_assembly_wf
    end

  end

  describe "is_accessioned()" do

    it "can exercise all logic branches" do
      # At each stage, we set a stub, call is_accessioned(), and then reverse the stub.
      wfs = Dor::WorkflowService
      # Not published: false.
      @go.stub(:is_published).and_return(false)
      @go.is_accessioned.should == false
      @go.stub(:is_published).and_return(true)
      # Running in development or test mode: true.
      @go.stub(:should_treat_as_accessioned).and_return(true)
      @go.is_accessioned.should == true
      @go.stub(:should_treat_as_accessioned).and_return(false)
      # Never accessioned: false.
      wfs.stub(:get_lifecycle).and_return(false)
      @go.is_accessioned.should == false
      wfs.stub(:get_lifecycle).and_return(true)
      # Accessioned but not archived: true.
      wfs.stub(:get_active_lifecycle).and_return(true)
      @go.is_accessioned.should == false
      wfs.stub(:get_active_lifecycle).and_return(false)
      # Survived all tests: true.
      @go.is_accessioned.should == true
    end

  end

  describe "publish_time()" do

    it "development and test mode: 1 day after submitted_for_publish_time" do
      spt = "2013-02-27T00:38:22Z"
      exp = "2013-02-28T00:38:22Z"
      @go.stub(:submitted_for_publish_time).and_return(spt)
      @go.publish_time.should == exp
    end

    it "production mode: query workflow service" do
      @go.stub(:should_treat_as_accessioned).and_return(false)
      exp = "2000-02-01T00:30:00Z"
      Dor::WorkflowService.stub(:get_lifecycle).and_return(exp)
      @go.publish_time.should == exp
    end

  end

  it "should_treat_as_accessioned(): can exercise" do
    @go.should_treat_as_accessioned.should == true
  end

end
