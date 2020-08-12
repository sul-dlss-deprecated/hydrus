# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RoleMetadataDatastreamIndexer do
  let(:obj) { Dor::AdminPolicyObject.new }

  let(:indexer) do
    described_class.new(resource: obj)
  end

  before do
    obj.roleMetadata.content = xml
  end

  describe '#to_solr' do
    subject(:doc) { indexer.to_solr }

    context 'when there are non-Hydrus roles' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <roleMetadata>
            <role type="dor-apo-manager">
              <group>
                <identifier type="workgroup">dlss:dor-admin</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
      end

      it 'has the fields used by argo' do
        expect(doc['apo_register_permissions_ssim']).to eq ['workgroup:dlss:dor-admin']
        expect(doc['apo_register_permissions_tesim']).to eq ['workgroup:dlss:dor-admin']
      end
    end

    context 'when there are hydrus roles' do
      let(:xml) do
        <<~XML
          <roleMetadata>
            <role type="hydrus-user">
              <group>
                <identifier type="workgroup">dlss:dor-admin</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
      end

      it 'does not index apo_register_permissions' do
        expect(doc).not_to have_key('apo_register_permissions_ssim')
        expect(doc).not_to have_key('apo_register_permissions_tesim')
      end
    end
  end
end
