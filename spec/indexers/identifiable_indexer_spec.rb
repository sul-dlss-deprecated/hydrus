# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdentifiableIndexer do
  let(:xml) do
    <<~XML
      <identityMetadata>
        <objectId>druid:rt923jk342</objectId>
        <objectType>item</objectType>
        <objectLabel>google download barcode 36105049267078</objectLabel>
        <objectCreator>DOR</objectCreator>
        <citationTitle>Squirrels of North America</citationTitle>
        <citationCreator>Eder, Tamara, 1974-</citationCreator>
        <sourceId source="google">STANFORD_342837261527</sourceId>
        <otherId name="barcode">36105049267078</otherId>
        <otherId name="catkey">129483625</otherId>
        <otherId name="uuid">7f3da130-7b02-11de-8a39-0800200c9a66</otherId>
        <tag>Google Books : Phase 1</tag>
        <tag>Google Books : Scan source STANFORD</tag>
        <tag>Project : Beautiful Books</tag>
        <tag>Registered By : blalbrit</tag>
        <tag>DPG : Beautiful Books : Octavo : newpri</tag>
        <tag>Remediated By : 4.15.4</tag>
        <release displayType="image" release="true" to="Searchworks" what="self" when="2015-07-27T21:44:26Z" who="lauraw15">true</release>
        <release displayType="image" release="true" to="Some_special_place" what="self" when="2015-08-31T23:59:59" who="atz">true</release>
      </identityMetadata>
    XML
  end

  let(:obj) { Dor::Abstract.new(pid: 'druid:rt923jk342') }

  let(:indexer) do
    described_class.new(resource: obj)
  end

  before do
    obj.identityMetadata.content = xml
    described_class.reset_cache!
  end

  describe '#identity_metadata_source' do
    it 'depends on remove_other_Id' do
      obj.identityMetadata.remove_other_Id('catkey', '129483625')
      obj.identityMetadata.remove_other_Id('barcode', '36105049267078')
      obj.identityMetadata.add_other_Id('catkey', '129483625')
      expect(indexer.identity_metadata_source).to eq 'Symphony'
      obj.identityMetadata.remove_other_Id('catkey', '129483625')
      obj.identityMetadata.add_other_Id('barcode', '36105049267078')
      expect(indexer.identity_metadata_source).to eq 'Symphony'
      obj.identityMetadata.remove_other_Id('barcode', '36105049267078')
      expect(indexer.identity_metadata_source).to eq 'DOR'
      obj.identityMetadata.remove_other_Id('foo', 'bar')
      expect(indexer.identity_metadata_source).to eq 'DOR'
    end

    it 'indexes metadata source' do
      expect(indexer.identity_metadata_source).to eq 'Symphony'
    end
  end

  describe '#to_solr' do
    let(:doc) { indexer.to_solr }

    context 'with related objects' do
      let(:mock_rel_druid) { 'druid:does_not_exist' }
      let(:mock_rels_ext_xml) do
        %(<rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
              xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
              <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
                <fedora-model:hasModel rdf:resource="info:fedora/testObject"/>
                <hydra:isGovernedBy rdf:resource="info:fedora/#{mock_rel_druid}"/>
                <fedora:isMemberOfCollection rdf:resource="info:fedora/#{mock_rel_druid}"/>
              </rdf:Description>
            </rdf:RDF>)
      end

      before do
        allow(obj.datastreams['RELS-EXT']).to receive(:content).and_return(mock_rels_ext_xml)
      end

      context 'when related collection and APOs are not found' do
        before do
          allow(Dor).to receive(:find).with(mock_rel_druid).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        it 'generate collections and apo title fields' do
          expect(doc[Solrizer.solr_name('collection_title', :symbol)].first).to eq mock_rel_druid
          expect(doc[Solrizer.solr_name('collection_title', :stored_searchable)].first).to eq mock_rel_druid
          expect(doc[Solrizer.solr_name('apo_title', :symbol)].first).to eq mock_rel_druid
          expect(doc[Solrizer.solr_name('apo_title', :stored_searchable)].first).to eq mock_rel_druid
          expect(doc[Solrizer.solr_name('nonhydrus_apo_title', :symbol)].first).to eq mock_rel_druid
          expect(doc[Solrizer.solr_name('nonhydrus_apo_title', :stored_searchable)].first).to eq mock_rel_druid
        end
      end

      context 'when related collection and APOs are found' do
        let(:mock_obj) { instance_double(Dor::Item, full_title: 'Test object') }

        before do
          allow(Dor).to receive(:find).with(mock_rel_druid).and_return(mock_obj)
          allow(indexer).to receive(:related_object_tags).and_return([])
        end

        it 'generate collections and apo title fields' do
          expect(doc[Solrizer.solr_name('collection_title', :symbol)].first).to eq 'Test object'
          expect(doc[Solrizer.solr_name('collection_title', :stored_searchable)].first).to eq 'Test object'
          expect(doc[Solrizer.solr_name('apo_title', :symbol)].first).to eq 'Test object'
          expect(doc[Solrizer.solr_name('apo_title', :stored_searchable)].first).to eq 'Test object'
          expect(doc[Solrizer.solr_name('nonhydrus_apo_title', :symbol)].first).to eq 'Test object'
          expect(doc[Solrizer.solr_name('nonhydrus_apo_title', :stored_searchable)].first).to eq  'Test object'
        end
      end
    end

    it 'indexes metadata source' do
      expect(doc).to match a_hash_including('metadata_source_ssi' => 'Symphony')
    end
  end

  describe '#related_object_tags' do
    context 'with a nil' do
      let(:object) { nil }

      it 'returns an empty array' do
        expect(indexer.send(:related_object_tags, object)).to eq([])
      end
    end

    context 'with an object that responds to #pid' do
      before do
        allow(Dor::Services::Client).to receive(:object).with(object.pid).and_return(fake_object_client)
      end

      let(:fake_object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: fake_tags_client) }
      let(:fake_tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: nil) }
      let(:object) { obj }

      it 'makes a dor-services-client call' do
        indexer.send(:related_object_tags, object)
        expect(fake_tags_client).to have_received(:list).once
      end
    end
  end

  describe '#related_obj_display_title' do
    subject { indexer.send(:related_obj_display_title, mock_apo_obj, mock_default_title) }

    let(:mock_default_title) { 'druid:zy098xw7654' }

    context 'when the main title is available' do
      let(:mock_apo_obj) { instance_double(Dor::AdminPolicyObject, full_title: 'apo title') }

      it { is_expected.to eq 'apo title' }
    end

    context 'when the first descMetadata main title entry is empty string' do
      let(:mock_apo_obj) { instance_double(Dor::AdminPolicyObject, full_title: nil) }

      it { is_expected.to eq mock_default_title }
    end

    context 'when the related object is nil' do
      let(:mock_apo_obj) { nil }

      it { is_expected.to eq mock_default_title }
    end
  end
end
