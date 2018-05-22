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
    describe('terms of acceptance for a new item', integration: true) do
      let(:item) { described_class.create(collection.pid, user) }
      let(:collection) { Hydrus::Collection.find('druid:oo000oo0003') }

      context 'if the user has already accepted another item in this collection but it was more than 1 year ago' do
        let(:user) { User.find_or_create_by(email: 'archivist1') } # this user accepted more than 1 year ago
        it 'indicates that a new item in a collection requires terms acceptance' do
          expect(collection.users_accepted_terms_of_deposit.keys.include?(user.email)).to eq(true)
          expect(item.requires_terms_acceptance(user, collection)).to eq(true)
          expect(item.accepted_terms_of_deposit).to eq('false')
          expect(item.terms_of_deposit_accepted?).to eq(false)
        end
      end

      context 'if the user has already accepted another item in this collection less than 1 year ago' do
        let(:user) { build_stubbed :archivist3 }
        before do
          dt = HyTime.now - 1.month # force this user to have accepted 1 month ago.
          collection.hydrusProperties.accept_terms_of_deposit(user, HyTime.datetime(dt))
          collection.save!
        end

        it 'indicates that a new item in a collection does not require terms acceptance' do
          expect(collection.users_accepted_terms_of_deposit.keys.include?(user.email)).to eq(true)
          expect(item.requires_terms_acceptance(user, collection)).to eq(false)
          expect(item.accepted_terms_of_deposit).to eq('true')
          expect(item.terms_of_deposit_accepted?).to eq(true)
        end
      end

      context 'when the user has not already accepted another item in this collection' do
        let(:user) { build_stubbed :archivist5 }
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
end
