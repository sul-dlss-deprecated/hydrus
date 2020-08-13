require 'spec_helper'

describe(HydrusSolrController, type: :feature, integration: true) do
  describe '#delete_from_index' do
    it 'removes items from solr' do
      expect(ActiveFedora.solr.conn).to receive(:delete_by_id).with('x')
      visit '/hydrus_solr/delete_from_index/x'
    end
  end

  describe '#reindex' do
    let(:druid) { 'druid:bb123bb1234' }
    let(:fake_object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: fake_tags_client) }
    let(:fake_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags) }
    let(:tags) { ['Project : Hydrus'] }

    let(:mock_hydrus_obj) { instance_double(Hydrus::Item, to_solr: { id: 'x' }, pid: druid) }
    let(:mock_indexer) { instance_double(CompositeIndexer::Instance, to_solr: mock_solr_doc) }
    let(:mock_solr_doc) { { id: druid } }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(fake_object_client)
      allow(Indexer).to receive(:for).with(mock_hydrus_obj).and_return(mock_indexer)
    end

    it 'indexes an item into solr' do
      allow(ActiveFedora::Base).to receive(:find).and_return(mock_hydrus_obj)
      expect(ActiveFedora.solr.conn).to receive(:add).with(hash_including(id: druid), anything)
      visit "/hydrus_solr/reindex/#{druid}"
    end
  end
end
