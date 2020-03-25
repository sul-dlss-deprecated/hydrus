# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ItemService do
  around do |example|
    @prev_mint_ids = Settings.suri.mint_ids
    Settings.suri.mint_ids = true
    example.run
    Settings.suri.mint_ids = @prev_mint_ids
  end

  describe '.create' do
    subject(:item) { described_class.create(collection.pid, user) }

    let(:fake_workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:fake_workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: fake_workflows_response) }
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      create_workflow_by_name: nil,
                      all_workflows_xml: '',
                      milestones: [],
                      workflow_routes: fake_workflow_routes)
    end

    let(:collection) { Hydrus::Collection.find('druid:bb000bb0003') }

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    end

    context 'if the user has already accepted another item in this collection but it was more than 1 year ago' do
      let(:user) { create :archivist1 } # this user accepted more than 1 year ago
      it 'indicates that a new item in a collection requires terms acceptance' do
        expect(collection.users_accepted_terms_of_deposit.keys.include?(user.sunetid)).to eq(true)
        expect(item.requires_terms_acceptance(user, collection)).to eq(true)
        expect(item.accepted_terms_of_deposit).to eq('false')
        expect(item.terms_of_deposit_accepted?).to eq(false)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(String, 'hydrusAssemblyWF',
                                                                                version: '1')
      end
    end

    context 'if the user has already accepted another item in this collection less than 1 year ago' do
      let(:user) { create :archivist3 }
      before do
        dt = HyTime.now - 1.month # force this user to have accepted 1 month ago.
        collection.hydrusProperties.accept_terms_of_deposit(user, HyTime.datetime(dt))
        collection.save!
      end

      it 'indicates that a new item in a collection does not require terms acceptance' do
        expect(collection.users_accepted_terms_of_deposit.keys.include?(user.sunetid)).to eq(true)
        expect(item.requires_terms_acceptance(user, collection)).to eq(false)
        expect(item.accepted_terms_of_deposit).to eq('true')
        expect(item.terms_of_deposit_accepted?).to eq(true)
      end
    end

    context 'when the user has not already accepted another item in this collection' do
      let(:user) { create :archivist5 }
      before do
        allow(Hydrus::Authorizable).to receive(:can_create_items_in).and_return(true)
      end

      it 'indicates that a new item in a collection requires terms acceptance' do
        expect(item.requires_terms_acceptance(user, collection)).to eq(true)
        expect(item.accepted_terms_of_deposit).to eq('false')
        expect(item.terms_of_deposit_accepted?).to eq(false)
      end
    end
  end
end
