# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Routes for manipulating the index', type: :routing do
  describe 'GET /dor/reindex' do
    it 'routes to #reindex' do
      expect(get('/dor/reindex/abc123')).to route_to('hydrus_solr#reindex', id: 'abc123')
    end
  end
  describe 'POST /dor/reindex' do
    it 'routes to #reindex' do
      expect(post('/dor/reindex/abc123')).to route_to('hydrus_solr#reindex', id: 'abc123')
    end
  end

  describe 'PUT /dor/reindex' do
    it 'routes to #reindex' do
      expect(put('/dor/reindex/abc123')).to route_to('hydrus_solr#reindex', id: 'abc123')
    end
  end

  describe 'GET /dor/delete_from_index' do
    it 'routes to #delete_from_index' do
      expect(get('/dor/delete_from_index/abc123')).to route_to('hydrus_solr#delete_from_index', id: 'abc123')
    end
  end
  describe 'POST /dor/delete_from_index' do
    it 'routes to #delete_from_index' do
      expect(post('/dor/delete_from_index/abc123')).to route_to('hydrus_solr#delete_from_index', id: 'abc123')
    end
  end
end
