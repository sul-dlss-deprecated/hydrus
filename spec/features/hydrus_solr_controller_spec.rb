# frozen_string_literal: true
require 'spec_helper'

describe(HydrusSolrController, type: :feature, integration: true) do
  describe '#delete_from_index' do
    it 'removes items from solr' do
      expect(Dor::SearchService.solr).to receive(:delete_by_id).with('x')
      visit '/hydrus_solr/delete_from_index/x'
    end
  end

  describe '#reindex' do
    it 'indexes an item into solr' do
      expect(Dor::SearchService.solr).to receive(:add).with(hash_including(id: 'druid:oo000oo0001'), anything)
      visit '/hydrus_solr/reindex/druid:oo000oo0001'
    end
  end
end
