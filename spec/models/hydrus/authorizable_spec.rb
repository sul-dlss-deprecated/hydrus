require 'spec_helper'

describe Hydrus::Authorizable do

  before(:each) do
    @auth = Hydrus::Authorizable
    @s0   = Set.new
    @s1   = Set.new(%w(aa bb cc))
    @s2   = Set.new(%w(dd ee ff))
    @s3   = Set.new(%w(bb ee))
    @ua   = double('mock_user', :sunetid => 'aa')
    @ub   = double('mock_user', :sunetid => 'bb')
    @uf   = double('mock_user', :sunetid => 'ff')
    @obj  = double('mock_fedora_obj')
    @hc   = double('mock_collecton')
    @hi   = double('mock_item')
  end

  it "should be able to exercise the methods returning fixed Sets" do
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

  it "does_intersect() should return true if the given sets intersect" do
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

  it "can_do_it() should dispatch to the correct method" do
    actions   = %w(read edit)
    obj_types = %w(collection item)
    obj_types.each do |typ|
      @obj.stub(:hydrus_class_to_s).and_return(typ)
      actions.each do |act|
        meth = "can_#{act}_#{typ}"
        @auth.should_receive(:send).with(meth, @ua, @obj).once
        @auth.can_do_it(act, @ua, @obj)
      end
    end
  end

  it "can_*_object() should return whatever can_do_it() returns" do
    [true, false].each do |exp|
      @auth.stub(:can_do_it).and_return(exp)
      @auth.can_read_object(@ua, @obj).should == exp
      @auth.can_edit_object(@us, @obj).should == exp
    end
  end

  describe "can_read_collection()" do

    it "should return true directly if the user has power to create collections" do
      @hc.should_not_receive(:roles_of_person)
      @auth.stub(:can_create_collections).and_return(true)
      @auth.can_read_collection(@ua, @hc).should == true
    end

    it "should return true if the user has any role in the collection/apo" do
      @auth.stub(:can_create_collections).and_return(false)
      # Roles in the APO.
      @hc.stub(:roles_of_person).and_return(@s1)
      @auth.can_read_collection(@ua, @hc).should == true
      # No roles.
      @hc.stub(:roles_of_person).and_return(@s0)
      @auth.can_read_collection(@uf, @hc).should == false
    end

  end

  describe "can_read_item()" do

    it "should return true directly if the user has power to create collections" do
      @hi.should_not_receive(:roles_of_person)
      @auth.stub(:can_create_collections).and_return(true)
      @auth.can_read_item(@ua, @hi).should == true
    end

    it "should return true if the user has any role in the item or the collection/apo" do
      @auth.stub(:can_create_collections).and_return(false)
      # Roles in the item, but not the APO.
      @hi.stub(:roles_of_person).and_return(@s1)
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s0)
      @auth.can_read_item(@ua, @hi).should == true
      # Roles in the APO, but not in the Item.
      @hi.stub(:roles_of_person).and_return(@s0)
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s1)
      @auth.can_read_item(@ua, @hi).should == true
      # No roles.
      @hi.stub(:roles_of_person).and_return(@s0)
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s0)
      @auth.can_read_item(@uf, @hi).should == false
    end

  end

  describe "can_create_items_in()" do

    it "should return true directly if the user is an administrator" do
      @hi.should_not_receive(:roles_of_person)
      @auth.stub(:is_administrator).and_return(true)
      @auth.can_create_items_in(@ua, @hc).should == true
    end

    it "should return true if the user has any of the item creator roles" do
      @auth.stub(:is_administrator).and_return(false)
      @auth.stub(:item_creator_roles).and_return(@s1)
      # Yes
      @hc.stub(:roles_of_person).and_return(@s3)
      @auth.can_create_items_in(@ua, @hc).should == true
      # No
      @hc.stub(:roles_of_person).and_return(@s2)
      @auth.can_create_items_in(@ua, @hc).should == false
    end

  end

  describe "can_edit_collection()" do

    it "should return true directly if the user is an administrator" do
      @hc.should_not_receive(:roles_of_person)
      @auth.stub(:is_administrator).and_return(true)
      @auth.can_edit_collection(@ua, @hc).should == true
    end

    it "should return true if the user has any of the collection editor roles" do
      @auth.stub(:is_administrator).and_return(false)
      @auth.stub(:collection_editor_roles).and_return(@s1)
      # Yes.
      @hc.stub(:roles_of_person).and_return(@s3)
      @auth.can_edit_collection(@ua, @hc).should == true
      # No.
      @hc.stub(:roles_of_person).and_return(@s2)
      @auth.can_edit_collection(@ua, @hc).should == false
    end

  end

  describe "can_edit_item()" do

    it "should return true directly if the user is an administrator" do
      @hi.should_not_receive(:roles_of_person)
      @auth.stub(:is_administrator).and_return(true)
      @auth.can_edit_item(@ua, @hi).should == true
    end

    it "should return true if the user has any of the item editor roles" do
      @auth.stub(:is_administrator).and_return(false)
      @auth.stub(:item_editor_roles).and_return(@s1)
      # Yes for the item, no for the APO.
      @hi.stub(:roles_of_person).and_return(@s3)
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s0)
      @auth.can_edit_item(@ua, @hi).should == true
      # Yes for the APO, no for the item.
      @hi.stub(:roles_of_person).and_return(@s0)
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s3)
      @auth.can_edit_item(@ua, @hi).should == true
      # No.
      @hi.stub(:roles_of_person).and_return(@s0)
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s0)
      @auth.can_edit_item(@ua, @hi).should == false
    end

  end

  describe "can_review_item()" do

    it "should return true directly if the user can edit the item's collection" do
      @hi.should_not_receive(:apo)
      @hi.stub(:collection)
      @auth.stub(:can_edit_collection).and_return(true)
      @auth.can_review_item(@ua, @hi).should == true
    end

    it "should return true if the user has any of the item editor roles" do
      @hi.stub(:collection)
      @auth.stub(:can_edit_collection).and_return(false)
      @auth.stub(:item_reviewer_roles).and_return(@s1)
      # Yes.
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s3)
      @auth.can_review_item(@ua, @hi).should == true
      # No.
      @hi.stub_chain(:apo, :roles_of_person).and_return(@s2)
      @auth.can_review_item(@ua, @hi).should == false
    end

  end

end
