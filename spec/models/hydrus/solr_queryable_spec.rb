require 'spec_helper'

# A mock class to use while testing out mixin.
class MockSolrQueryable
  include Hydrus::SolrQueryable
end

describe Hydrus::SolrQueryable do

  before(:each) do
    @msq  = MockSolrQueryable.new
    @hsq  = Hydrus::SolrQueryable
    @user = 'userFoo'
    @role_md_clause = %Q<roleMetadata_role_person_identifier_t:"#{@user}">
  end

  describe "add_involved_user_filter() modifies the SOLR :fq parameters" do
    
    it "should do nothing if there is no user" do
      h = {}
      @hsq.add_involved_user_filter(h, nil)
      h[:fq].should == nil
    end

    it "should add the expected :fq clause" do
      tests = [
        [ false, {},                [@role_md_clause] ],
        [ true,  {},                [@role_md_clause] ],
        [ false, {:fq => []},       [@role_md_clause] ],
        [ true,  {:fq => []},       [@role_md_clause] ],
        [ false, {:fq => ['blah']}, ['blah', @role_md_clause] ],
        [ true,  {:fq => ['blah']}, ["blah OR #{@role_md_clause}"] ],
      ]
      tests.each do |use_or, h, exp|
        @hsq.add_involved_user_filter(h, @user, :or => use_or)
        h[:fq].should == exp
      end
    end

  end

  describe "add_governed_by_filter() modifies the SOLR :fq parameters" do
    
    it "should do nothing if no druids are supplied" do
      h = {}
      @hsq.add_governed_by_filter(h, [])
      h[:fq].should == nil
    end

    it "should add the expected :fq clause" do
      druids = %w(aaa bbb)
      igb    = 'is_governed_by_s:("info:fedora/aaa" OR "info:fedora/bbb")'
      tests  = [
        [ {},                [igb] ],
        [ {:fq => []},       [igb] ],
        [ {:fq => ['blah']}, ['blah', igb] ],
      ]
      tests.each do |h, exp|
        @hsq.add_governed_by_filter(h, druids)
        h[:fq].should == exp
      end
    end

  end

  describe "add_model_filter() modifies the SOLR :fq parameters" do
    
    it "should do nothing if no models are supplied" do
      h = {}
      @hsq.add_model_filter(h)
      h[:fq].should == nil
    end

    it "should add the expected :fq clause" do
      models = %w(xxx yyy)
      hms    = 'has_model_s:("info:fedora/afmodel:xxx" OR "info:fedora/afmodel:yyy")'
      tests  = [
        [ {},                [hms] ],
        [ {:fq => []},       [hms] ],
        [ {:fq => ['blah']}, ['blah', hms] ],
      ]
      tests.each do |h, exp|
        @hsq.add_model_filter(h, *models)
        h[:fq].should == exp
      end
    end

  end

  it "squery_*() methods should return hashes of SOLR query parameters with expected keys" do
    # No need to check in greater details, because all of the detailed
    # work is done by methods already tested.
    h = @msq.squery_apos_involving_user(@user)
    Set.new(h.keys).should == Set.new([:rows, :fl, :q, :fq])
    h = @msq.squery_collections_of_apos(['a', 'b'])
    Set.new(h.keys).should == Set.new([:rows, :fl, :q, :fq])
    h = @msq.squery_item_counts_of_collections(['c', 'd'])
    Set.new(h.keys).should == Set.new([:rows, :fl, :q, :facet, :'facet.pivot', :fq])
  end

end
