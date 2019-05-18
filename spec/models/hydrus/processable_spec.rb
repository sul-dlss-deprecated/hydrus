require 'spec_helper'

describe Hydrus::Processable, type: :model do
  let(:mock_wf_client) { instance_double(Dor::Workflow::Client) }

  before(:each) do
    @cannot_do_regex = /\ACannot perform action/
    @go = Hydrus::GenericObject.new
    allow(Dor::Workflow::Client).to receive(:new).and_return(mock_wf_client)
    allow(mock_wf_client).to receive(:update_workflow_status)
  end

  describe 'complete_workflow_step()' do
    it 'can exercise the method, stubbing out call to WF service' do
      step = 'submit'
      args = ['dor', @go.pid, 'hydrusAssemblyWF', step, 'completed']
      expect(mock_wf_client).to receive(:update_workflow_status).with(*args)
      allow(@go).to receive_message_chain(:workflows, :workflow_step_is_done).and_return(false)
      expect(@go).to receive(:workflows_content_is_stale)
      @go.complete_workflow_step(step)
    end
  end

  it 'can exercise uncomplete_workflow_steps() stubbed' do
    expect(@go).to receive(:update_workflow_status).exactly(3).times
    @go.uncomplete_workflow_steps()
  end

  it 'can exercise workflows_content_is_stale, stubbed' do
    expect(@go.workflows).to receive(:instance_variable_set).twice
    @go.workflows_content_is_stale
  end

  describe 'start_common_assembly()' do
    it 'should raise exception if the object is not assemblable' do
      allow(@go).to receive(:is_assemblable).and_return(false)
      expect { @go.start_common_assembly }.to raise_exception(@cannot_do_regex)
    end

    it 'can exercise the method for an item, calling the right methods, stubbed' do
      allow(@go).to receive(:is_assemblable).and_return(true)
      allow(@go).to receive(:is_item?).and_return(true)
      expect(@go).to receive(:delete_missing_files).once
      expect(@go).to receive(:create_druid_tree).once
      expect(@go).to receive(:update_content_metadata).once
      expect(@go).to receive(:complete_workflow_step).once
      expect(@go).to receive(:start_assembly_wf).once
      @go.start_common_assembly
    end

    it 'can exercise the method for a non-item, only calling the right methods, stubbed' do
      allow(@go).to receive(:is_assemblable).and_return(true)
      allow(@go).to receive(:is_item?).and_return(false)
      expect(@go).not_to receive(:delete_missing_files)
      expect(@go).to receive(:create_druid_tree).once
      expect(@go).not_to receive(:update_content_metadata)
      expect(@go).to receive(:complete_workflow_step).once
      expect(@go).to receive(:start_assembly_wf).once
      @go.start_common_assembly
    end
  end

  describe 'start_assembly_wf()' do
    it 'should do nothing if the app is not configured to start assemblyWF' do
      allow(@go).to receive(:should_start_assembly_wf).and_return(false)
      expect(Dor::Workflow::Client).not_to receive(:create_workflow_by_name)
      @go.start_assembly_wf
    end

    it 'can exercise should_start_assembly_wf()' do
      expect(@go.should_start_assembly_wf).to eq(Dor::Config.hydrus.start_assembly_wf)
    end
  end

  describe 'is_accessioned()' do
    it 'can exercise all logic branches' do
      # At each stage, we set a stub, call is_accessioned(), and then reverse the stub.
      # Not published: false.
      allow(@go).to receive(:is_published).and_return(false)
      expect(@go.is_accessioned).to eq(false)
      allow(@go).to receive(:is_published).and_return(true)
      # Running in development or test mode: true.
      allow(@go).to receive(:should_treat_as_accessioned).and_return(true)
      expect(@go.is_accessioned).to eq(true)
      allow(@go).to receive(:should_treat_as_accessioned).and_return(false)
      # Never accessioned: false.
      allow(mock_wf_client).to receive(:lifecycle).and_return(false)
      expect(@go.is_accessioned).to eq(false)
      allow(mock_wf_client).to receive(:lifecycle).and_return(true)
      # Survived all tests: true.
      expect(@go.is_accessioned).to eq(true)
    end
  end

  describe 'publish_time()' do
    it 'development and test mode: 1 day after submitted_for_publish_time' do
      spt = '2013-02-27T00:38:22Z'
      exp = '2013-02-28T00:38:22Z'
      allow(@go).to receive(:submitted_for_publish_time).and_return(spt)
      expect(@go.publish_time).to eq(exp)
    end

    it 'production mode: query workflow service' do
      allow(@go).to receive(:should_treat_as_accessioned).and_return(false)
      exp = '2000-02-01T00:30:00Z'
      allow(mock_wf_client).to receive(:lifecycle).and_return(exp)
      expect(@go.publish_time).to eq(exp)
    end
  end

  it 'should_treat_as_accessioned(): can exercise' do
    expect(@go.should_treat_as_accessioned).to eq(true)
  end
end
