require 'spec_helper'

# Note: other behavior is exercised in integration tests.

RSpec.describe HydrusSolrController, type: :controller do
  let(:pid) { 'druid:bc123df4567' }

  describe 'reindex' do
    before do
      allow(Indexer).to receive(:for).with(mock_hydrus_obj).and_return(mock_indexer)
    end

    let(:mock_hydrus_obj) { instance_double(Hydrus::Item, to_solr: { id: 'x' }, pid: pid) }
    let(:mock_indexer) { instance_double(CompositeIndexer::Instance, to_solr: mock_solr_doc) }
    let(:mock_solr_doc) { { id: pid } }
  
    context 'when an object is not found in Fedora' do
      it 'responds with 404' do
        allow(ActiveFedora::Base).to receive(:find).and_return(nil)
        get :reindex, params: { id: pid }
        expect(response.status).to eq(404)
        expect(response.body).to include('failed to find object')
      end
    end

    context 'with a non-Hydrus object' do
      let(:fake_tags_client) do
        instance_double(Dor::Services::Client::AdministrativeTags, list: [])
      end

      before do
        allow(controller).to receive(:tags_client).and_return(fake_tags_client)
      end

      it 'skips reindexing the object' do
        allow(ActiveFedora::Base).to receive(:find).and_return(instance_double(Dor::Item, pid: pid))
        get :reindex, params: { id: pid }
        expect(response.status).to eq(200)
        expect(response.body).to include('skipped')
      end
    end

    context 'with a Hydrus object' do
      let(:fake_tags_client) do
        instance_double(Dor::Services::Client::AdministrativeTags, list: ['Project : Hydrus'])
      end

      before do
        allow(controller).to receive(:tags_client).and_return(fake_tags_client)
      end

      it 'indexes the object' do
        allow(ActiveFedora::Base).to receive(:find)
          .and_return(mock_hydrus_obj)
        expect(ActiveFedora.solr.conn).to receive(:add).with({ id: pid }, add_attributes: { commitWithin: 5000 }).and_return(true)
        get :reindex, params: { id: 'druid:bc123df4567' }
        expect(response.status).to eq(200)
      end
    end

    context 'with a tag containing the Hydrus project prefix' do
      let(:fake_tags_client) do
        instance_double(Dor::Services::Client::AdministrativeTags, list: ['Project : Hydrus : IR : data'])
      end

      before do
        allow(controller).to receive(:tags_client).and_return(fake_tags_client)
      end

      it 'indexes the object' do
        allow(ActiveFedora::Base).to receive(:find)
          .and_return(mock_hydrus_obj)
        expect(ActiveFedora.solr.conn).to receive(:add).with({ id: pid }, add_attributes: { commitWithin: 5000 }).and_return(true)
        get :reindex, params: { id: 'druid:bc123df4567' }
        expect(response.status).to eq(200)
      end
    end
  end
end
