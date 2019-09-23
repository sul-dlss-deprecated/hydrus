require 'spec_helper'

RSpec.describe Hydrus::Processable, type: :model do
  before do
    @cannot_do_regex = /\ACannot perform action/
    @go = Hydrus::GenericObject.new
  end

  describe 'complete_workflow_step()' do
    let(:wfs) { instance_double(Dor::Workflow::Client) }
    let(:step) { 'submit' }

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(wfs)
    end

    it 'can exercise the method, stubbing out call to WF service' do
      expect(wfs).to receive(:update_status).with(druid: @go.pid,
                                                  workflow: 'hydrusAssemblyWF',
                                                  process: step,
                                                  status: 'completed')
      allow(@go).to receive_message_chain(:workflows, :workflow_step_is_done).and_return(false)
      expect(@go).to receive(:workflows_content_is_stale)
      @go.complete_workflow_step(step)
    end
  end

  describe '#start_hydrus_wf' do
    subject(:start_hydrus_wf) { @go.start_hydrus_wf }

    let(:wfs) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true) }

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(wfs)
    end

    it 'creates a workflow' do
      start_hydrus_wf
      expect(wfs).to have_received(:create_workflow_by_name).with(@go.pid, 'hydrusAssemblyWF', version: '1')
    end
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

  describe '#start_assembly_wf' do
    let(:wfs) { instance_double(Dor::Workflow::Client) }
    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(wfs)
    end

    it 'does nothing if the app is not configured to start assemblyWF' do
      allow(@go).to receive(:should_start_assembly_wf).and_return(false)
      expect(wfs).not_to receive(:create_workflow_by_name)
      @go.start_assembly_wf
    end

    it 'can exercise should_start_assembly_wf()' do
      expect(@go.should_start_assembly_wf).to eq(Dor::Config.hydrus.start_assembly_wf)
    end
  end

  describe 'version_openable?' do
    let(:object_client) { instance_double(Dor::Services::Client::Object) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion) }

    before do
      allow(@go).to receive(:is_published).and_return(true)
      allow(@go).to receive(:should_treat_as_accessioned).and_return(false)
      allow(version_client).to receive(:openable?).and_return(true)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(object_client).to receive(:version).and_return(version_client)
    end

    context 'when item has not been published' do
      before do
        allow(@go).to receive(:is_published).and_return(false)
      end

      it 'returns false' do
        expect(@go.version_openable?).to eq(false)
      end
    end
    context 'when published, but dor-services-app reports a new version cannot be opened' do
      before do
        allow(version_client).to receive(:openable?).and_return(false)
      end

      it 'returns false' do
        expect(@go.version_openable?).to eq(false)
      end
    end

    context 'when published and dor-services-app reports a new version can be opened' do
      it 'returns true' do
        expect(@go.version_openable?).to eq(true)
      end
    end
  end

  describe 'publish_time()' do
    let(:wfs) { instance_double(Dor::Workflow::Client) }
    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(wfs)
    end

    it 'development and test mode: 1 day after submitted_for_publish_time' do
      spt = '2013-02-27T00:38:22Z'
      exp = '2013-02-28T00:38:22Z'
      allow(@go).to receive(:submitted_for_publish_time).and_return(spt)
      expect(@go.publish_time).to eq(exp)
    end

    it 'production mode: query workflow service' do
      allow(@go).to receive(:should_treat_as_accessioned).and_return(false)
      exp = '2000-02-01T00:30:00Z'
      allow(wfs).to receive(:lifecycle).and_return(exp)
      expect(@go.publish_time).to eq(exp)
    end
  end

  it 'should_treat_as_accessioned(): can exercise' do
    expect(@go.should_treat_as_accessioned).to eq(true)
  end
end
