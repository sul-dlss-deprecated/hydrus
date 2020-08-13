# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasableIndexer do
  let(:obj) { instance_double(Dor::Abstract, pid: 'druid:pz263ny9658') }

  describe 'to_solr' do
    let(:doc) { described_class.new(resource: obj).to_solr }
    let(:released_for_info) do
      {
        'Project' => { 'release' => true },
        'test_target' => { 'release' => true },
        'test_nontarget' => { 'release' => false }
      }
    end
    let(:released_to_field_name) { Solrizer.solr_name('released_to', :symbol) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: tags_client) }
    let(:tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: released_for_info) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'indexes release tags' do
      expect(doc).to eq(released_to_field_name => %w[Project test_target])
    end
  end
end
