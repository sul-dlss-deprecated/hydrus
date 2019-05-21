# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ItemService do
  around do |example|
    @prev_mint_ids = Dor::Config.configure.suri.mint_ids
    Dor::Config.configure.suri.mint_ids = true
    example.run
    Dor::Config.configure.suri.mint_ids = @prev_mint_ids
  end

  describe '.create' do
    subject(:item) { described_class.create(collection.pid, user) }

    let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
    let(:collection) { Hydrus::Collection.find('druid:oo000oo0003') }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    context 'if the user has already accepted another item in this collection but it was more than 1 year ago' do
      let(:user) { create :archivist1 } # this user accepted more than 1 year ago
      it 'indicates that a new item in a collection requires terms acceptance' do
        expect(collection.users_accepted_terms_of_deposit.keys.include?(user.sunetid)).to eq(true)
        expect(item.requires_terms_acceptance(user, collection)).to eq(true)
        expect(item.accepted_terms_of_deposit).to eq('false')
        expect(item.terms_of_deposit_accepted?).to eq(false)
        expect(workflow_client).to have_received(:create_workflow_by_name).with(String, 'hydrusAssemblyWF')
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
