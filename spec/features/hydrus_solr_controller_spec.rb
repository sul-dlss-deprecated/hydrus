require 'spec_helper'

describe(HydrusSolrController, type: :feature, integration: true) do
  describe '#delete_from_index' do
    it 'removes items from solr' do
      expect(ActiveFedora.solr.conn).to receive(:delete_by_id).with('x')
      visit '/hydrus_solr/delete_from_index/x'
    end
  end

  describe '#reindex' do
    it 'indexes an item into solr' do
      expect(ActiveFedora.solr.conn).to receive(:add).with(hash_including(id: 'druid:bb123bb1234'), anything)
      visit '/hydrus_solr/reindex/druid:bb123bb1234'
    end
  end
end
