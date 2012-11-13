require 'spec_helper'

class MockHydrusObject
  include Hydrus::SolrQueryable
end

describe(HydrusSolrController, :integration => true) do

  def get_solr_docs
    obj = MockHydrusObject.new
    h = {
      :rows => 9999, 
      :q    => '*',
      :fl   => 'identityMetadata_objectId_t',
    }
    resp = obj.issue_solr_query(h).first['response']
    druids = resp['docs'].map { |d| d['identityMetadata_objectId_t'].first  }
    n      = resp['numFound']
    return n, druids
  end

  it "should be able to execute delete_from_index() and reindex() actions" do
    # Determine N of documents in the SOLR index,
    # and confirm that all of these PIDs are in the index.
    pids = %w(
      druid:oo000oo0001
      druid:oo000oo0002
      druid:oo000oo0003
    )
    n_initial, druids = get_solr_docs()
    pids.all? { |p| druids.include?(p) }.should == true
    # Delete the documents with those PIDs.
    # The SOLR index should have fewer docs, none of them with our PIDs.
    pids.each do |pid|
      visit "/hydrus_solr/delete_from_index/#{pid}"
    end
    n, druids = get_solr_docs()
    n.should == n_initial - pids.size
    pids.none? { |p| druids.include?(p) }.should == true
    # Re-solarize the objects we just removed from the index.
    # We should be back to the initial state.
    pids.each do |pid|
      visit "/hydrus_solr/reindex/#{pid}"
    end
    sleep 5  # Need to give SOLR time to reindex.
    n, druids = get_solr_docs()
    n.should == n_initial
    pids.all? { |p| druids.include?(p) }.should == true
  end
  
end
