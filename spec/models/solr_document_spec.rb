require 'spec_helper'

RSpec.describe SolrDocument, type: :model do
  describe '#object_title' do
    subject(:title) { solr_doc.object_title }
    let(:solr_doc) { described_class.new(values) }

    before do
      # Don't index workflow stuff
      allow_any_instance_of(Dor::ProcessableIndexer).to receive(:to_solr).and_return({})
    end

    context 'for a new item' do
      let(:values) { Hydrus::Item.new.to_solr }
      it 'is untitled' do
        expect(title).to eq 'Untitled'
      end
    end

    context 'for a new Hydrus::Collection' do
      let(:values) { Hydrus::Collection.new.to_solr }
      it 'is untitled' do
        expect(title).to eq 'Untitled'
      end
    end
  end

  describe '#route_key' do
    it 'should be hydrus_collection for a Dor::Collection' do
      sdoc = SolrDocument.new has_model_ssim: 'info:fedora/afmodel:Dor_Collection'
      expect(sdoc.route_key).to eq('hydrus_collection')
    end

    it 'should be hydrus_item for a Dor::Item' do
      sdoc = SolrDocument.new has_model_ssim: 'info:fedora/afmodel:Dor_Item'
      expect(sdoc.route_key).to eq('hydrus_item')
    end
  end

  it 'can exercise to_model(), stubbed' do
    sdoc = SolrDocument.new
    id = 998877
    allow(sdoc).to receive(:id).and_return(id)
    expect(ActiveFedora::Base).to receive(:load_instance_from_solr).with(id, sdoc)
    sdoc.to_model()
  end

  it 'can exercise simple getters' do
    h = {
      'main_title_ssm' => 'foo title',
      'objectId_ssim' => 'foo:pid',
      'has_model_ssim'                 => 'info:fedora/afmodel:Hydrus_Item',
      'object_status_ssim'             => 'awaiting_approval',
      'item_depositor_person_identifier_ssm' => 'foo_user',
    }
    sdoc = SolrDocument.new h
    expect(sdoc.main_title).to    eq(h['main_title_ssm'])
    expect(sdoc.pid).to           eq(h['objectId_ssim'])
    expect(sdoc.object_type).to   eq('item')
    expect(sdoc.object_status).to eq('waiting for approval')
    expect(sdoc.depositor).to     eq('foo_user')
    expect(sdoc.path).to          eq('/items/foo:pid')
  end
end
