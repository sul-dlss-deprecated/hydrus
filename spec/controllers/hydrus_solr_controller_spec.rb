require 'spec_helper'

# Note: other behavior is exercised in integration tests.

RSpec.describe HydrusSolrController, type: :controller do
  describe 'reindex()' do
    it 'responds with 404 if object is not in Fedora' do
      bogus_pid = 'druid:BLAH'
      allow(ActiveFedora::Base).to receive(:find).and_return(nil)
      get :reindex, params: { id: bogus_pid }
      expect(response.status).to eq(404)
      expect(response.body).to include('failed to find object')
    end

    it 'skips non-Hydrus objects' do
      some_pid = 'druid:oo000oo9999'
      allow(ActiveFedora::Base).to receive(:find).and_return(Object.new)
      get :reindex, params: { id: some_pid }
      expect(response.status).to eq(200)
      expect(response.body).to include('skipped')
    end

    it 'indexes Hydrus objects' do
      allow(ActiveFedora::Base).to receive(:find).and_return(instance_double(Hydrus::Item, tags: ['Project : Hydrus'], to_solr: { id: 'x' }))
      expect(ActiveFedora.solr.conn).to receive(:add).with({ id: 'x' }, add_attributes: { commitWithin: 5000 }).and_return(true)
      get :reindex, params: { id: 'druid:oo000oo9999' }
      expect(response.status).to eq(200)
    end

    it 'indexes Hydrus objects tagged with our project prefix' do
      allow(ActiveFedora::Base).to receive(:find).and_return(instance_double(Hydrus::Item, tags: ['Project : Hydrus : IR : data'], to_solr: { id: 'x' }))
      expect(ActiveFedora.solr.conn).to receive(:add).with({ id: 'x' }, add_attributes: { commitWithin: 5000 }).and_return(true)
      get :reindex, params: { id: 'druid:oo000oo9999' }
      expect(response.status).to eq(200)
    end
  end
end
