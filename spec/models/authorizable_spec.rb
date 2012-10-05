require 'spec_helper'

describe Hydrus::Authorizable do

  before(:each) do
    @auth = Hydrus::Authorizable
    @s1   = Set.new(%w(aa bb cc))
    @s2   = Set.new(%w(dd ee ff))
    @s3   = Set.new(%w(bb ee))
    @ua   = double('mock_user', :sunetid => 'aa')
    @ub   = double('mock_user', :sunetid => 'bb')
    @uf   = double('mock_user', :sunetid => 'ff')
  end

  it "should be able to exercise the methods returning Sets" do
    methods = [
      :administrators,
      :collection_creators,
      :collection_editor_roles,
      :item_creator_roles,
      :item_editor_roles,
      :item_reviewer_roles,
    ]
    methods.each do |m|
      @auth.send(m).should be_instance_of(Set)
    end
  end

  it "does_intersect() should work as expected" do
    @auth.does_intersect(@s1, @s2).should == false
    @auth.does_intersect(@s1, @s3).should == true
  end
    
  it "is_administrator() should work as expected" do
    @auth.stub(:administrators).and_return(@s1)
    @auth.is_administrator(@ua).should == true
    @auth.is_administrator(@uf).should == false
  end
    
  it "can_create_collections() should work as expected" do
    @auth.stub(:collection_creators).and_return(@s1)
    @auth.can_create_collections(@ua).should == true
    @auth.can_create_collections(@uf).should == false
  end
    
end
