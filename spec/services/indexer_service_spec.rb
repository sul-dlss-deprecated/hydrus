# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Indexer do
  subject { described_class.for(obj) }

  context 'for a collection' do
    let(:obj) { Hydrus::Collection.new }
    it { is_expected.not_to be_nil }
  end
end
