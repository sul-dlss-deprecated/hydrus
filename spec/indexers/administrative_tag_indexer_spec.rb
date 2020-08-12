# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdministrativeTagIndexer do
  describe '#to_solr' do
    subject(:document) { indexer.to_solr }

    let(:indexer) { described_class.new(resource: object) }
    let(:object) { Dor::Abstract.new(pid: 'druid:rt923jk234') }
    let(:tags) do
      [
        'Google Books : Phase 1',
        'Google Books : Scan source STANFORD',
        'Project : Beautiful Books',
        'Registered By : blalbrit',
        'DPG : Beautiful Books : Octavo : newpri',
        'Remediated By : 4.15.4'
      ]
    end

    before do
      # Don't actually hit the dor-services-app API endpoint
      allow(indexer).to receive(:administrative_tags).and_return(tags)
    end

    it 'indexes all administrative tags' do
      expect(document).to include('tag_ssim' => tags)
    end

    it 'indexes exploded tags' do
      expect(document['exploded_tag_ssim']).to match_array(
        [
          'Google Books',
          'Google Books : Phase 1',
          'Google Books',
          'Google Books : Scan source STANFORD',
          'Project',
          'Project : Beautiful Books',
          'Registered By',
          'Registered By : blalbrit',
          'DPG',
          'DPG : Beautiful Books',
          'DPG : Beautiful Books : Octavo',
          'DPG : Beautiful Books : Octavo : newpri',
          'Remediated By',
          'Remediated By : 4.15.4'
        ]
      )
    end

    it 'indexes prefixed tags' do
      expect(document).to include(
        'project_tag_ssim' => ['Beautiful Books'],
        'registered_by_tag_ssim' => ['blalbrit']
      )
    end
  end
end
