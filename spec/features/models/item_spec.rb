require 'spec_helper'

RSpec.describe Hydrus::Item, type: :feature, integration: true do
  describe 'Content metadata generation' do
    it 'generates content metadata, returning blank CM when no files exist and setting content metadata stream to a blank template' do
      xml = '<contentMetadata objectId="__DO_NOT_USE__" type="file"/>'
      hi = Hydrus::Item.new pid: '__DO_NOT_USE__'
      hi.update_content_metadata
      expect(hi.datastreams['contentMetadata'].content).to be_equivalent_to(xml)
    end

    it 'generates content metadata, returning and setting correct cm when files exist' do
      item = Hydrus::Item.find('druid:bb123bb1234')
      expect(item.files.size).to eq(4)
      expect(item.datastreams['contentMetadata'].content).to be_equivalent_to '<contentMetadata></contentMetadata>'
      item.update_content_metadata
      expect(item.datastreams['contentMetadata'].content).to be_equivalent_to <<-EOF
      <contentMetadata objectId="bb123bb1234" type="file">
        <resource id="bb123bb1234_1" sequence="1" type="file">
          <label>Main survey -- formatted in HTML</label>
          <file id="pinocchio.htm" preserve="yes" publish="yes" shelve="yes"/>
        </resource>
        <resource id="bb123bb1234_2" sequence="2" type="file">
          <label>Main survey -- as plain text (extracted into CSV tables)</label>
          <file id="pinocchio.-punctuation_in=file.name.txt" preserve="yes" publish="no" shelve="no"/>
        </resource>
        <resource id="bb123bb1234_3" sequence="3" type="file">
          <label>Main survey -- as PDF (prepared May 17, 2012)</label>
          <file id="pinocchio characters tc in file name.pdf" preserve="yes" publish="yes" shelve="yes"/>
        </resource>
        <resource id="bb123bb1234_4" sequence="4" type="file">
          <label>Imagine this is a set of data samples</label>
          <file id="pinocchio_using_a_rather_long_filename-2012-05-17.zip" preserve="yes" publish="yes" shelve="yes"/>
        </resource>
      </contentMetadata>
      EOF
    end
  end

  describe '#accept_terms_of_deposit' do
    let(:user_key) { 'archivist5' }
    let(:user) { create :archivist5 }
    let(:item) { ItemService.create(collection.pid, user) }
    let(:collection) { Hydrus::Collection.find('druid:bb000bb0003') }

    before do
      allow(Hydrus::Authorizable).to receive(:can_create_items_in).and_return(true)
      allow(Hydrus::Authorizable).to receive(:can_edit_item).and_return(true)
    end

    it 'accepts the terms for an item, updating the appropriate hydrusProperties metadata in item and collection' do
      expect(item.requires_terms_acceptance(user_key, collection)).to eq(true)
      expect(item.accepted_terms_of_deposit).to eq('false')
      expect(collection.users_accepted_terms_of_deposit.keys.include?(user_key)).to eq(false)
      item.accept_terms_of_deposit(user)
      expect(item.accepted_terms_of_deposit).to eq('true')
      expect(item.terms_of_deposit_accepted?).to eq(true)
      collection.reload
      expect(collection.users_accepted_terms_of_deposit.keys.include?(user_key)).to eq(true)
      expect(collection.users_accepted_terms_of_deposit[user_key].nil?).to eq(false)
    end
  end

  describe 'do_publish' do
    let(:fake_workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:fake_workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: fake_workflows_response) }
    let(:user) { create :archivist1 }
    let(:wfs) do
      instance_double(Dor::Workflow::Client,
                      all_workflows_xml: '',
                      milestones: [],
                      update_status: nil,
                      create_workflow_by_name: nil,
                      workflow_routes: fake_workflow_routes)
    end

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(wfs)
    end

    it 'modifies workflows' do
      druid = 'druid:bb000bb0003'
      hi    = ItemService.create(druid, user)
      allow(hi).to receive(:should_start_assembly_wf).and_return(true)
      allow(hi).to receive(:is_assemblable).and_return(true)
      hi.do_publish
      expect(wfs).to have_received(:update_status).with(druid: hi.pid,
                                                        workflow: 'hydrusAssemblyWF',
                                                        process: 'approve',
                                                        status: 'completed')
      expect(wfs).to have_received(:update_status).with(druid: hi.pid,
                                                        workflow: 'hydrusAssemblyWF',
                                                        process: 'start-assembly',
                                                        status: 'completed')
      expect(wfs).to have_received(:create_workflow_by_name).with(hi.pid, 'assemblyWF', version: '1')
    end
  end

  describe 'create()' do
    let(:user) { create :archivist1 }

    before do
      allow(Hydrus::Collection).to receive(:find).with(collection.pid).and_return(collection)
    end

    let(:collection) do
      Hydrus::Collection.create(user).tap do |col|
        allow(col).to receive_messages(is_open: true)
      end
    end

    it 'creates an item' do
      allow_any_instance_of(Dor::WorkflowDs).to receive(:current_priority).and_return 0
      allow(collection).to receive_messages(visibility_option_value: 'stanford', license: 'some-license')
      item = ItemService.create(collection.pid, user, 'some-type')
      expect(item).to be_instance_of Hydrus::Item
      expect(item).to_not be_new_record
      expect(item.visibility).to include 'stanford'
      expect(item.item_type).to eq 'some-type'
      expect(item.events.event.val.size).to eq(1)
      expect(item.events.event.to_a).to include 'Item created'
      expect(item.object_status).to eq 'draft'
      expect(item.versionMetadata).to_not be_new
      expect(item.license).to eq 'some-license'
      expect(item.roleMetadata.item_depositor.to_a).to include user.sunetid
      expect(item.relationships(:has_model)).to_not include 'info:fedora/afmodel:Dor_Item'
      expect(item.relationships(:has_model)).to include 'info:fedora/afmodel:Hydrus_Item'
      expect(item.accepted_terms_of_deposit).to eq 'false'
    end

    it 'creates another item' do
      allow_any_instance_of(Dor::WorkflowDs).to receive(:current_priority).and_return 0
      allow(collection).to receive_messages(users_accepted_terms_of_deposit: { user.to_s => Time.now })
      item = ItemService.create(collection.pid, user, 'some-type')
      expect(item).to be_instance_of Hydrus::Item
      expect(item).to_not be_new_record
      expect(item.item_type).to eq 'some-type'
      expect(item.events.event.to_a).to include 'Terms of deposit accepted due to previous item acceptance in collection'
      expect(item.accepted_terms_of_deposit).to eq 'true'
    end
  end
end
