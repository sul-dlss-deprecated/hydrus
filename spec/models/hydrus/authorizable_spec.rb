require 'spec_helper'

describe Hydrus::Authorizable, :type => :model do

  before(:each) do
    @auth = Hydrus::Authorizable
    @s0   = Set.new
    @s1   = Set.new(%w(aa bb cc))
    @s2   = Set.new(%w(dd ee ff))
    @s3   = Set.new(%w(bb ee))
    @ua   = double('mock_user', :sunetid => 'aa', :is_administrator? => false, :is_collection_creator? => false, :is_global_viewer? => false)
    @ub   = double('mock_user', :sunetid => 'bb')
    @uf   = double('mock_user', :sunetid => 'ff', :is_administrator? => false, :is_collection_creator? => false, :is_global_viewer? => false)
    @obj  = double('mock_fedora_obj')
    @hc   = double('mock_collecton')
    @hi   = double('mock_item')
  end
  
  let(:admin_user) { double('mock_admin', :is_administrator? => true ) }
  let(:creator_user) { double('mock_creator', :is_collection_creator? => true ) }
  let(:viewer_user) { double('mock_viewer', :is_global_viewer? => true ) }

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
      expect(@auth.send(m)).to be_instance_of(Set)
    end
  end

  it "does_intersect() should return true if the given sets intersect" do
    expect(@auth.does_intersect(@s1, @s2)).to eq(false)
    expect(@auth.does_intersect(@s1, @s3)).to eq(true)
  end

  describe "administrators" do

    it "is_administrator() should work as expected" do
      allow(@auth).to receive(:administrators).and_return(@s1)
      expect(@auth.is_administrator(@ua)).to eq(true)
      expect(@auth.is_administrator(@uf)).to eq(false)
    end

    it "can_act_as_administrator() should be like is_administrator(), except in dev" do
      # In test environment, is_administrator() should determine outcome.
      expect(Rails.env).to eq('test')
      [true, false].each do |exp|
        allow(@auth).to receive(:is_administrator).and_return(exp)
        expect(@auth.can_act_as_administrator(nil)).to eq(exp)
      end
      # In development environment, should return true even for non-admins.
      allow(Rails).to receive(:env).and_return('development')
      allow(@auth).to receive(:is_administrator).and_return(false)
      expect(@auth.can_act_as_administrator(nil)).to eq(true)
    end

  end

  describe "User model attributes" do
    it "should be an admin if the user says it is" do
      expect(@auth.can_act_as_administrator(admin_user)).to be_truthy
    end

    it "should be a collection creator if the user says it is" do
      expect(@auth.can_create_collections(creator_user)).to be_truthy
    end
    
    it "should be a collection creator if the user says it is" do
      expect(@auth.is_global_viewer(viewer_user)).to be_truthy
    end
  end


  it "can_create_collections() should work as expected" do
    allow(@auth).to receive(:collection_creators).and_return(@s1)
    expect(@auth.can_create_collections(@ua)).to eq(true)
    expect(@auth.can_create_collections(@uf)).to eq(false)
  end

  it "is_global_viewer() should work as expected" do
    allow(@auth).to receive(:global_viewers).and_return(@s1)
    expect(@auth.is_global_viewer(@ua)).to eq(true)
    expect(@auth.is_global_viewer(@uf)).to eq(false)
  end

  describe "can_do_it()" do

    it "should return false if given nil object" do
      expect(@auth.can_do_it('foo', 'bar', nil)).to eq(false)
    end

    it "should dispatch to the correct method" do
      actions   = %w(read edit)
      obj_types = %w(collection item)
      obj_types.each do |typ|
        allow(@obj).to receive(:hydrus_class_to_s).and_return(typ)
        actions.each do |act|
          meth = "can_#{act}_#{typ}"
          expect(@auth).to receive(:send).with(meth, @ua, @obj).once
          @auth.can_do_it(act, @ua, @obj)
        end
      end
    end

  end

  it "can_*_object() should return whatever can_do_it() returns" do
    [true, false].each do |exp|
      allow(@auth).to receive(:can_do_it).and_return(exp)
      expect(@auth.can_read_object(@ua, @obj)).to eq(exp)
      expect(@auth.can_edit_object(@us, @obj)).to eq(exp)
    end
  end

  describe "can_read_collection()" do

    it "should return true directly if the user has power to create collections" do
      expect(@hc).not_to receive(:roles_of_person)
      allow(@auth).to receive(:is_global_viewer).and_return(true)
      expect(@auth.can_read_collection(@ua, @hc)).to eq(true)
    end

    it "should return true if the user has any role in the collection/apo" do
      allow(@auth).to receive(:is_global_viewer).and_return(false)
      # Roles in the APO.
      allow(@hc).to receive(:roles_of_person).and_return(@s1)
      expect(@auth.can_read_collection(@ua, @hc)).to eq(true)
      # No roles.
      allow(@hc).to receive(:roles_of_person).and_return(@s0)
      expect(@auth.can_read_collection(@uf, @hc)).to eq(false)
    end

  end

  describe "can_read_item()" do

    it "should return true directly if the user has power to create collections" do
      expect(@hi).not_to receive(:roles_of_person)
      allow(@auth).to receive(:is_global_viewer).and_return(true)
      expect(@auth.can_read_item(@ua, @hi)).to eq(true)
    end

    it "should return true if the user has any role in the item or the collection/apo" do
      allow(@auth).to receive(:is_global_viewer).and_return(false)
      # Roles in the item, but not the APO.
      allow(@hi).to receive(:roles_of_person).and_return(@s1)
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s0)
      expect(@auth.can_read_item(@ua, @hi)).to eq(true)
      # Roles in the APO, but not in the Item.
      allow(@hi).to receive(:roles_of_person).and_return(@s0)
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s1)
      expect(@auth.can_read_item(@ua, @hi)).to eq(true)
      # No roles.
      allow(@hi).to receive(:roles_of_person).and_return(@s0)
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s0)
      expect(@auth.can_read_item(@uf, @hi)).to eq(false)
    end

  end

  describe "can_create_items_in()" do

    it "should return false if given a nil object" do
      expect(@hi).not_to receive(:is_administrator)
      expect(@auth.can_create_items_in(@ua, nil)).to eq(false)
    end

    it "should return true directly if the user is an administrator" do
      expect(@hi).not_to receive(:roles_of_person)
      allow(@auth).to receive(:is_administrator).and_return(true)
      expect(@auth.can_create_items_in(@ua, @hc)).to eq(true)
    end

    it "should return true if the user has any of the item creator roles" do
      allow(@auth).to receive(:is_administrator).and_return(false)
      allow(@auth).to receive(:item_creator_roles).and_return(@s1)
      # Yes
      allow(@hc).to receive(:roles_of_person).and_return(@s3)
      expect(@auth.can_create_items_in(@ua, @hc)).to eq(true)
      # No
      allow(@hc).to receive(:roles_of_person).and_return(@s2)
      expect(@auth.can_create_items_in(@ua, @hc)).to eq(false)
    end

  end

  describe "can_edit_collection()" do

    it "should return true directly if the user is an administrator" do
      expect(@hc).not_to receive(:roles_of_person)
      allow(@auth).to receive(:is_administrator).and_return(true)
      expect(@auth.can_edit_collection(@ua, @hc)).to eq(true)
    end

    it "should return true if the user has any of the collection editor roles" do
      allow(@auth).to receive(:is_administrator).and_return(false)
      allow(@auth).to receive(:collection_editor_roles).and_return(@s1)
      # Yes.
      allow(@hc).to receive(:roles_of_person).and_return(@s3)
      expect(@auth.can_edit_collection(@ua, @hc)).to eq(true)
      # No.
      allow(@hc).to receive(:roles_of_person).and_return(@s2)
      expect(@auth.can_edit_collection(@ua, @hc)).to eq(false)
    end

  end

  describe "can_edit_item()" do

    it "should return true directly if the user is an administrator" do
      expect(@hi).not_to receive(:roles_of_person)
      allow(@auth).to receive(:is_administrator).and_return(true)
      expect(@auth.can_edit_item(@ua, @hi)).to eq(true)
    end

    it "should return true if the user has any of the item editor roles" do
      allow(@auth).to receive(:is_administrator).and_return(false)
      allow(@auth).to receive(:item_editor_roles).and_return(@s1)
      # Yes for the item, no for the APO.
      allow(@hi).to receive(:roles_of_person).and_return(@s3)
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s0)
      expect(@auth.can_edit_item(@ua, @hi)).to eq(true)
      # Yes for the APO, no for the item.
      allow(@hi).to receive(:roles_of_person).and_return(@s0)
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s3)
      expect(@auth.can_edit_item(@ua, @hi)).to eq(true)
      # No.
      allow(@hi).to receive(:roles_of_person).and_return(@s0)
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s0)
      expect(@auth.can_edit_item(@ua, @hi)).to eq(false)
    end

  end

  describe "can_review_item()" do

    it "should return true directly if the user can edit the item's collection" do
      expect(@hi).not_to receive(:apo)
      allow(@hi).to receive(:collection)
      allow(@auth).to receive(:can_edit_collection).and_return(true)
      expect(@auth.can_review_item(@ua, @hi)).to eq(true)
    end

    it "should return true if the user has any of the item editor roles" do
      allow(@hi).to receive(:collection)
      allow(@auth).to receive(:can_edit_collection).and_return(false)
      allow(@auth).to receive(:item_reviewer_roles).and_return(@s1)
      # Yes.
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s3)
      expect(@auth.can_review_item(@ua, @hi)).to eq(true)
      # No.
      allow(@hi).to receive_message_chain(:apo, :roles_of_person).and_return(@s2)
      expect(@auth.can_review_item(@ua, @hi)).to eq(false)
    end

  end

end
