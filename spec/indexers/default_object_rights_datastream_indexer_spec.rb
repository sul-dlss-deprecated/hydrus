# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DefaultObjectRightsDatastreamIndexer do
  let(:obj) do
    Dor::AdminPolicyObject.new
  end

  let(:indexer) do
    described_class.new(resource: obj)
  end

  describe '#to_solr' do
    let(:indexer) do
      CompositeIndexer.new(
        described_class
      ).new(resource: obj)
    end
    let(:doc) { indexer.to_solr }

    before do
      obj.use_statement = 'Rights are owned by Stanford University Libraries.'
      obj.copyright_statement = 'Additional copyright info'
    end

    it 'makes a solr doc' do
      expect(doc).to match a_hash_including('use_statement_ssim' =>
        ['Rights are owned by Stanford University Libraries.'])
      expect(doc).to match a_hash_including('copyright_ssim' => ['Additional copyright info'])
    end
  end
end
