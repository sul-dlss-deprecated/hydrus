require 'spec_helper'

# A mock class to use while testing out mixin.
class MockSolrQueryable
  include Hydrus::SolrQueryable
end

describe Hydrus::SolrQueryable, type: :model do

  before(:each) do
    @msq  = MockSolrQueryable.new
    @hsq  = Hydrus::SolrQueryable
    @user = 'userFoo'
    @role_md_clause = %Q<role_person_identifier_sim:"#{@user}">
  end

  describe '.add_gated_discovery' do
    it 'should OR the facets for objects that involve the user and are governed by APOs the user has access to ' do
      h = {}
      @hsq.add_gated_discovery(h, ['aaa', 'bbb'], @user)
      expect(h[:fq].size).to eq(1)

      expect(h[:fq].first).to eq 'is_governed_by_ssim:("info:fedora/aaa" OR "info:fedora/bbb") OR ' + @role_md_clause
    end
  end

  describe 'add_involved_user_filter() modifies the SOLR :fq parameters' do

    it 'should do nothing if there is no user' do
      h = {}
      @hsq.add_involved_user_filter(h, nil)
      expect(h[:fq]).to eq(nil)
    end

    it 'should add the expected :fq clause' do
      tests = [
        [ {},                [@role_md_clause] ],
        [ {fq: []},       [@role_md_clause] ],
        [ {fq: ['blah']}, ['blah', @role_md_clause] ],
      ]
      tests.each do |h, exp|
        @hsq.add_involved_user_filter(h, @user)
        expect(h[:fq]).to eq(exp)
      end
    end

  end

  describe 'add_governed_by_filter() modifies the SOLR :fq parameters' do

    it 'should do nothing if no druids are supplied' do
      h = {}
      @hsq.add_governed_by_filter(h, [])
      expect(h[:fq]).to eq(nil)
    end

    it 'should add the expected :fq clause' do
      druids = %w(aaa bbb)
      igb    = 'is_governed_by_ssim:("info:fedora/aaa" OR "info:fedora/bbb")'
      tests  = [
        [ {},                [igb] ],
        [ {fq: []},       [igb] ],
        [ {fq: ['blah']}, ['blah', igb] ],
      ]
      tests.each do |h, exp|
        @hsq.add_governed_by_filter(h, druids)
        expect(h[:fq]).to eq(exp)
      end
    end

  end

  describe 'add_model_filter() modifies the SOLR :fq parameters' do

    it 'should do nothing if no models are supplied' do
      h = {}
      @hsq.add_model_filter(h)
      expect(h[:fq]).to eq(nil)
    end

    it 'should add the expected :fq clause' do
      models = %w(xxx yyy)
      hms    = 'has_model_ssim:("info:fedora/afmodel:xxx" OR "info:fedora/afmodel:yyy")'
      tests  = [
        [ {},                [hms] ],
        [ {fq: []},       [hms] ],
        [ {fq: ['blah']}, ['blah', hms] ],
      ]
      tests.each do |h, exp|
        @hsq.add_model_filter(h, *models)
        expect(h[:fq]).to eq(exp)
      end
    end

  end

  it 'squery_*() methods should return hashes of SOLR query parameters with expected keys' do
    # No need to check in greater details, because all of the detailed
    # work is done by methods already tested.
    h = @msq.squery_apos_involving_user(@user)
    expect(Set.new(h.keys)).to eq(Set.new([:rows, :fl, :q, :fq]))
    h = @msq.squery_collections_of_apos(['a', 'b'])
    expect(Set.new(h.keys)).to eq(Set.new([:rows, :fl, :q, :fq]))
    h = @msq.squery_item_counts_of_collections(['c', 'd'])
    expect(Set.new(h.keys)).to eq(Set.new([:rows, :'facet.limit', :fl, :q, :facet, :'facet.pivot', :fq]))
    h = @msq.squery_all_hydrus_collections()
    expect(Set.new(h.keys)).to eq(Set.new([:rows, :fl, :q, :fq]))
  end

  it 'can exercise get_druids_from_response()' do
    k    = 'objectId_ssim'
    exp  = [12, 34, 56]
    docs = exp.map { |n| {k => [n]} }
    resp = double('resp', docs: docs)
    expect(@msq.get_druids_from_response(resp)).to eq(exp)
  end

  # Note: These are integration tests.
  describe('all_hydrus_objects()', integration: true) do

    before(:each) do
      @all_objects = [
        {pid: 'druid:oo000oo0001', object_type: 'Item',              object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0002', object_type: 'AdminPolicyObject', object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0003', object_type: 'Collection',        object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0004', object_type: 'Collection',        object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0005', object_type: 'Item',              object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0006', object_type: 'Item',              object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0007', object_type: 'Item',              object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0008', object_type: 'AdminPolicyObject', object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0009', object_type: 'AdminPolicyObject', object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0010', object_type: 'Collection',        object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0011', object_type: 'Item',              object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0012', object_type: 'Item',              object_version: '2013.02.26a'},
        {pid: 'druid:oo000oo0013', object_type: 'Item',              object_version: '2013.02.26a'}
      ]
    end

    it 'should get all Hydrus objects, with the correct info' do
      got = @msq.all_hydrus_objects.sort_by { |h| h[:pid] }
      expect(got).to eq(@all_objects)
    end

    it 'should get all Hydrus objects -- but only an array of PIDs' do
      got = @msq.all_hydrus_objects(pids_only: true).sort
      exp = @all_objects.map { |h| h[:pid] }
      expect(got).to eq(exp)
    end

    it 'should all Items and Collections, with the correct info' do
      ms = [Hydrus::Collection, Hydrus::Item]
      got = @msq.all_hydrus_objects(models: ms).sort_by { |h| h[:pid] }
      exp = @all_objects.reject { |h| h[:object_type] == 'AdminPolicyObject' }
      expect(got).to eq(exp)
    end

  end
  describe 'queries should send their parameters via post' do
    it 'should not fail if the query is very long' do
      fake_pids=[]
      1000.times do
        fake_pids << 'fake_pid'
      end
      h = @msq.squery_item_counts_of_collections(fake_pids)
      #this raises an exception due to receiving a 413 error from solr unless the parameters are posted
      expect{resp, sdocs = @msq.issue_solr_query(h)}.not_to raise_error
    end
  end

end
