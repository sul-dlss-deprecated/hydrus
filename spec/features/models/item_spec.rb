require 'spec_helper'

describe(Hydrus::Item, type: :feature, integration: true) do
  describe('Content metadata generation') do
    it 'should be able to generate content metadata, returning blank CM when no files exist and setting content metadata stream to a blank template' do
      xml = '<contentMetadata objectId="__DO_NOT_USE__" type="file"/>'
      hi = Hydrus::Item.new pid: '__DO_NOT_USE__'
      hi.update_content_metadata
      expect(hi.datastreams['contentMetadata'].content).to be_equivalent_to(xml)
    end

    it 'should be able to generate content metadata, returning and setting correct cm when files exist' do
      item = Hydrus::Item.find('druid:oo000oo0001')
      expect(item.files.size).to eq(4)
      expect(item.datastreams['contentMetadata'].content).to be_equivalent_to '<contentMetadata></contentMetadata>'
      item.update_content_metadata
      expect(item.datastreams['contentMetadata'].content).to be_equivalent_to <<-EOF
      <contentMetadata objectId="oo000oo0001" type="file">
        <resource id="oo000oo0001_1" sequence="1" type="file">
          <label>Main survey -- formatted in HTML</label>
          <file id="pinocchio.htm" preserve="yes" publish="yes" shelve="yes"/>
        </resource>
        <resource id="oo000oo0001_2" sequence="2" type="file">
          <label>Main survey -- as plain text (extracted into CSV tables)</label>
          <file id="pinocchio.-punctuation_in=file.name.txt" preserve="yes" publish="no" shelve="no"/>
        </resource>
        <resource id="oo000oo0001_3" sequence="3" type="file">
          <label>Main survey -- as PDF (prepared May 17, 2012)</label>
          <file id="pinocchio characters tc in file name.pdf" preserve="yes" publish="yes" shelve="yes"/>
        </resource>
        <resource id="oo000oo0001_4" sequence="4" type="file">
          <label>Imagine this is a set of data samples</label>
          <file id="pinocchio_using_a_rather_long_filename-2012-05-17.zip" preserve="yes" publish="yes" shelve="yes"/>
        </resource>
      </contentMetadata>
      EOF
    end
  end

  describe '#accept_terms_of_deposit' do
    let(:user_key) { 'archivist5' }
    let(:user) { mock_authed_user(user_key) }
    let(:item) { ItemService.create(collection.pid, user) }
    let(:collection) { Hydrus::Collection.find('druid:oo000oo0003') }

    before do
      allow(Hydrus::Authorizable).to receive(:can_create_items_in).and_return(true)
      allow(Hydrus::Authorizable).to receive(:can_edit_item).and_return(true)
    end

    around do |example|
      @prev_mint_ids = Dor::Config.configure.suri.mint_ids
      Dor::Config.configure.suri.mint_ids = true
      example.run
      Dor::Config.configure.suri.mint_ids = @prev_mint_ids
    end

    it 'should accept the terms for an item, updating the appropriate hydrusProperties metadata in item and collection' do
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

  describe 'do_publish()' do
    before(:each) do
      @prev_mint_ids = config_mint_ids()
    end

    after(:each) do
      config_mint_ids(@prev_mint_ids)
    end

    it 'should modify workflows as expected' do
      # Setup.
      druid = 'druid:oo000oo0003'
      hi    = ItemService.create(druid, mock_authed_user)
      wf    = Dor::Config.hydrus.app_workflow
      steps = Dor::Config.hydrus.app_workflow_steps
      exp   = Hash[ steps.map { |s| [s, 'waiting'] } ]
      # Code to check workflow statuses.
      check_statuses = lambda {
        hi = Hydrus::Item.find(hi.pid)  # A refreshed copy of object.
        statuses = steps.map { |s| [s, hi.workflows.get_workflow_status(s)] }
        expect(Hash[statuses]).to eq(exp)
      }
      # Initial statuses.
      exp['start-deposit'] = 'completed'
      check_statuses.call()
      # After running do_publish, with start_assembly_wf=true.
      allow(hi).to receive(:should_start_assembly_wf).and_return(true)
      allow(hi).to receive(:is_assemblable).and_return(true)
      expect(Dor::WorkflowService).to receive(:create_workflow).once
      hi.do_publish()
      exp['approve'] = 'completed'
      exp['start-assembly'] = 'completed'
      check_statuses.call()
    end
  end

  describe 'create()' do
    before(:all) do
      @prev_mint_ids = config_mint_ids()
      @collection = Hydrus::Collection.create mock_authed_user
    end

    after(:all) do
      @collection.delete
      config_mint_ids(@prev_mint_ids)
    end

    before(:each) do
      allow(Hydrus::Collection).to receive(:find).with(collection.pid).and_return(collection)
    end

    let(:collection) do
      allow(@collection).to receive_messages(is_open: true)
      @collection
    end

    it 'should create an item' do
      allow_any_instance_of(Dor::WorkflowDs).to receive(:current_priority).and_return 0
      allow(collection).to receive_messages(visibility_option_value: 'stanford', license: 'some-license')
      item = ItemService.create(collection.pid, mock_authed_user, 'some-type')
      expect(item).to be_instance_of Hydrus::Item
      expect(item).to_not be_new
      expect(item.visibility).to include 'stanford'
      expect(item.item_type).to eq 'some-type'
      expect(item.events.event.val.size).to eq(1)
      expect(item.events.event.to_a).to include 'Item created'
      expect(item.object_status).to eq 'draft'
      expect(item.versionMetadata).to_not be_new
      expect(item.license).to eq 'some-license'
      expect(item.roleMetadata.item_depositor.to_a).to include mock_authed_user.sunetid
      expect(item.relationships(:has_model)).to_not include 'info:fedora/afmodel:Dor_Item'
      expect(item.relationships(:has_model)).to include 'info:fedora/afmodel:Hydrus_Item'
      expect(item.accepted_terms_of_deposit).to eq 'false'
    end

    it 'should create another item' do
      allow_any_instance_of(Dor::WorkflowDs).to receive(:current_priority).and_return 0

      allow(collection).to receive_messages(users_accepted_terms_of_deposit: { mock_authed_user.to_s => Time.now})
      item = ItemService.create(collection.pid, mock_authed_user, 'some-type')
      expect(item).to be_instance_of Hydrus::Item
      expect(item).to_not be_new
      expect(item.item_type).to eq 'some-type'
      expect(item.events.event.to_a).to include 'Terms of deposit accepted due to previous item acceptance in collection'
      expect(item.accepted_terms_of_deposit).to eq 'true'
    end
  end
end
