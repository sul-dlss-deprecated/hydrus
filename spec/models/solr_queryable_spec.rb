require 'spec_helper'

# A mock class to use while testing out mixin.
class MockSolrQueryable
  include Hydrus::SolrQueryable
end

describe Hydrus::SolrQueryable do

  before(:each) do
    @obj = MockSolrQueryable.new
  end

  it "squery_*() methods should return a hash of SOLR query parameters" do
    h = @obj.squery_apos_involving_user('user')
    h.should include(:rows, :fl, :q)
    h = @obj.squery_collections_of_apos(['a', 'b'])
    h.should include(:rows, :fl, :q)
    h = @obj.squery_item_counts_of_collections(['c', 'd'])
    h.should include(:rows, :fl, :q, :facet, :'facet.pivot')
  end

end
