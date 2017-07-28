require 'spec_helper'

describe Ability, type: :model do

  before(:all) do
    @af = ActiveFedora::Base.new
  end

  before(:each) do
    @auth = Hydrus::Authorizable
    allow(@auth).to receive(:can_create_collections).and_return(false)
    allow(@auth).to receive(:is_administrator).and_return(false)
    @obj  = Object.new
    @ab   = Ability.new(@obj)
    @dru  = 'some_pid'
  end

  describe 'get_fedora_object()' do
    
    it 'if given non-String, just return it' do
      obj = 1234
      expect(@ab.get_fedora_object(obj)).to eq(obj)
    end

    it 'if given String that is a valid pid, should return fedora object' do
      allow(ActiveFedora::Base).to receive(:find).and_return(@af)
      expect(@ab.get_fedora_object(@dru)).to eq(@af)
    end

    it 'if given String that is not valid pid, should return nil' do
      allow(ActiveFedora::Base).to receive(:find) { raise ActiveFedora::ObjectNotFoundError }
      expect(@ab.get_fedora_object(@dru)).to eq(nil)
    end

  end

  describe 'hydra_default_permissions' do

    before(:each) do
      allow(@ab).to receive(:get_fedora_object)
    end

    context 'for a user who can read an object' do
      before do
        allow(@auth).to receive(:can_read_object).and_return(true)
      end

      it 'has :read permission' do
        expect(@ab.can?(:read, @dru)).to eq(true)
        expect(@ab.can?(:read, @af)).to  eq(true)
      end
    end

    context 'for a user who cannot read an object' do
      before do
        allow(@auth).to receive(:can_read_object).and_return(false)
      end

      it 'does not have :read permission' do
        expect(@ab.can?(:read, @dru)).to eq(false)
        expect(@ab.can?(:read, @af)).to  eq(false)
      end
    end

    context 'for a user who can create collections' do
      before do
        allow(@auth).to receive(:can_create_collections).and_return(true)
        @ab = Ability.new(@obj)
      end

      it 'has :create permission for a collection' do
        expect(@ab.can?(:create, Hydrus::Collection)).to eq(true)
      end
    end

    context 'for a user who cannot create collections' do
      it 'does not have :create permission for a collection' do
        expect(@ab.can?(:create, Hydrus::Collection)).to eq(false)
      end
    end

    context 'for a user who can create items in a collection' do
      before do
        allow(@auth).to receive(:can_create_items_in).and_return(true)
      end

      it 'has :create_items_in permission for a collection' do
        expect(@ab.can?(:create_items_in, @dru)).to eq(true)
      end
    end

    context 'for a user who cannot create items in a collections' do
      before do
        allow(@auth).to receive(:can_create_items_in).and_return(false)
      end

      it 'does not have :create_items_in permission for a collection' do
        expect(@ab.can?(:create_items_in, @dru)).to eq(false)
      end
    end

    context 'for a user who can edit items' do
      before do
        allow(@auth).to receive(:can_edit_object).and_return(true)
      end

      it 'has :create_items_in permission for a collection' do
        expect(@ab.can?(:edit, @dru)).to eq(true)
        expect(@ab.can?(:edit, @af)).to  eq(true)
      end
    end

    context 'for a user who cannot edit items' do
      before do
        allow(@auth).to receive(:can_edit_object).and_return(false)
      end

      it 'does not have :create_items_in permission for a collection' do
        expect(@ab.can?(:edit, @dru)).to eq(false)
        expect(@ab.can?(:edit, @af)).to  eq(false)
      end
    end

    context 'for a user who can review items' do
      before do
        allow(@auth).to receive(:can_review_item).and_return(true)
      end

      it 'has :create_items_in permission for a collection' do
        expect(@ab.can?(:review, @dru)).to eq(true)
        expect(@ab.can?(:review, @af)).to  eq(true)
      end
    end

    context 'for a user who cannot review items' do
      before do
        allow(@auth).to receive(:can_review_item).and_return(false)
      end

      it 'does not have :create_items_in permission for a collection' do
        expect(@ab.can?(:review, @dru)).to eq(false)
        expect(@ab.can?(:review, @af)).to  eq(false)
      end
    end

    describe ':destroy' do
      it 'does not grant permission' do
        expect(@ab.can?(:destroy, @dru)).to eq(false)
        expect(@ab.can?(:destroy, @af)).to  eq(false)
      end
    end

    context 'for an administrator' do
      before do
        allow(@auth).to receive(:can_act_as_administrator).and_return(true)
        @ab = Ability.new(@obj)
      end
      it 'grants admin abilities' do
        expect(@ab.can?(:list_all_collections, nil)).to eq(true)
        expect(@ab.can?(:view_datastreams, @dru)).to eq(true)
        expect(@ab.can?(:view_datastreams, @af)).to  eq(true)
      end
    end
  end
end
