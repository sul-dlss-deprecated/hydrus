# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RightsMetadataDatastreamIndexer do
  let(:xml) do
    <<~XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
        <use>
          <human type="useAndReproduction">Official WTO documents are free for public use.</human>
          <human type="creativeCommons"/>
          <machine type="creativeCommons">by-nc-nd</machine>
        </use>
        <copyright>
          <human>Copyright &#xA9; World Trade Organization</human>
        </copyright>
      </rightsMetadata>
    XML
  end

  let(:obj) { Dor::Item.new(pid: 'druid:rt923jk342') }
  let(:rights_md_ds) { obj.rightsMetadata }

  let(:indexer) do
    described_class.new(resource: obj)
  end

  before do
    rights_md_ds.content = xml
  end

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    it 'has the fields used by argo' do
      expect(doc).to include(
        'copyright_ssim' => ['Copyright © World Trade Organization'],
        'use_statement_ssim' => ['Official WTO documents are free for public use.'],
        'use_license_machine_ssi' => 'by-nc-nd',
        'rights_descriptions_ssim' => ['world']
      )
    end

    describe 'legacy tests to_solr' do
      let(:mock_dra_obj) { instance_double(Dor::RightsAuth, index_elements: index_elements) }

      before do
        allow(rights_md_ds).to receive(:dra_object).and_return(mock_dra_obj)
      end

      context 'when access is restricted' do
        let(:index_elements) do
          {
            primary: 'access_restricted',
            errors: [],
            terms: [],
            obj_locations_qualified: [{ location: 'someplace', rule: 'somerule' }],
            file_groups_qualified: [{ group: 'somegroup', rule: 'someotherrule' }]
          }
        end

        it 'filters access_restricted from what gets aggregated into rights_descriptions_ssim' do
          expect(doc).to match a_hash_including(
            'rights_primary_ssi' => 'access_restricted',
            'rights_descriptions_ssim' => ['location: someplace (somerule)', 'somegroup (file) (someotherrule)']
          )
        end
      end

      context 'when it is world qualified' do
        let(:index_elements) do
          {
            primary: 'world_qualified',
            errors: [],
            terms: [],
            obj_world_qualified: [{ rule: 'somerule' }]
          }
        end

        it 'filters world_qualified from what gets aggregated into rights_descriptions_ssim' do
          expect(doc).to match a_hash_including(
            'rights_primary_ssi' => 'world_qualified',
            'rights_descriptions_ssim' => ['world (somerule)']
          )
        end
      end

      context 'with file_rights' do
        let(:index_elements) do
          {
            primary: 'access_restricted',
            errors: [],
            terms: [],
            obj_locations: ['location'],
            file_locations: ['file_specific_location'],
            obj_agents: ['agent'],
            file_agents: ['file_specific_agent']
          }
        end

        it 'includes the simple fields that are present' do
          expect(doc).to match a_hash_including(
            'obj_rights_locations_ssim' => ['location'],
            'file_rights_locations_ssim' => ['file_specific_location'],
            'obj_rights_agents_ssim' => ['agent'],
            'file_rights_agents_ssim' => ['file_specific_agent']
          )
        end
      end
    end
  end
end
