require 'spec_helper'

describe Ability, :type => :model do

  before(:all) do
    @af = ActiveFedora::Base.new
    @sd = SolrDocument.new
  end

  before(:each) do
    @auth = Hydrus::Authorizable
    allow(@auth).to receive(:can_create_collections).and_return(false)
    allow(@auth).to receive(:is_administrator).and_return(false)
    @obj  = Object.new
    @ab   = Ability.new(@obj)
    @dru  = 'some_pid'
  end

  describe "get_fedora_object()" do
    
    it "if given non-String, just return it" do
      obj = 1234
      expect(@ab.get_fedora_object(obj)).to eq(obj)
    end

    it "if given String that is a valid pid, should return fedora object" do
      allow(ActiveFedora::Base).to receive(:find).and_return(@af)
      expect(@ab.get_fedora_object(@dru)).to eq(@af)
    end

    it "if given String that is not valid pid, should return nil" do
      allow(ActiveFedora::Base).to receive(:find) { raise ActiveFedora::ObjectNotFoundError }
      expect(@ab.get_fedora_object(@dru)).to eq(nil)
    end

  end

  describe "hydra_default_permissions" do

    before(:each) do
      allow(@ab).to receive(:get_fedora_object)
    end

    it ":read should be based on can_read_object()" do
      [true, false].each do |exp|
        allow(@auth).to receive(:can_read_object).and_return(exp)
        expect(@ab.can?(:read, @dru)).to eq(exp)
        expect(@ab.can?(:read, @af)).to  eq(exp)
      end
    end

    it ":read for non-String, non-AF types of objects should be false" do
      expect(@ab.can?(:read, 1234)).to eq(false)
      expect(@ab.can?(:read, @sd)).to  eq(false)
    end

    it ":create_collections should be based on can_create_collections()" do
      [true, false].each do |exp|
        allow(@auth).to receive(:can_create_collections).and_return(exp)
        @ab = Ability.new(@obj)
        expect(@ab.can?(:create, Hydrus::Collection)).to eq(exp)
      end
    end

    it ":create_items_in should be based on can_create_items_in()" do
      [true, false].each do |exp|
        allow(@auth).to receive(:can_create_items_in).and_return(exp)
        expect(@ab.can?(:create_items_in, @dru)).to eq(exp)
      end
    end

    it ":edit should be based on can_edit_object()" do
      [true, false].each do |exp|
        allow(@auth).to receive(:can_edit_object).and_return(exp)
        expect(@ab.can?(:edit, @dru)).to eq(exp)
        expect(@ab.can?(:edit, @af)).to  eq(exp)
      end
    end

    it ":edit for non-String, non-AF types of objects should be false" do
      expect(@ab.can?(:edit, 1234)).to eq(false)
      expect(@ab.can?(:edit, @sd)).to  eq(false)
    end

    it ":review should be based on can_review_item()" do
      [true, false].each do |exp|
        allow(@auth).to receive(:can_review_item).and_return(exp)
        expect(@ab.can?(:review, @dru)).to eq(exp)
        expect(@ab.can?(:review, @af)).to  eq(exp)
      end
    end

    it ":destroy should be false" do
      expect(@ab.can?(:destroy, @dru)).to eq(false)
      expect(@ab.can?(:destroy, @af)).to  eq(false)
      expect(@ab.can?(:destroy, @sd)).to  eq(false)
    end

    it "admin abilities should be based on can_act_as_administrator()" do
      [true, false].each do |exp|
        allow(@auth).to receive(:can_act_as_administrator).and_return(exp)
        @ab = Ability.new(@obj)
        expect(@ab.can?(:list_all_collections, nil)).to eq(exp)
        expect(@ab.can?(:view_datastreams, @dru)).to eq(exp)
        expect(@ab.can?(:view_datastreams, @af)).to  eq(exp)
      end
    end

  end

end
