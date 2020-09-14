require 'spec_helper'

describe DatastreamsController, type: :controller do
  before do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    allow(controller).to receive_messages(current_ability: @ability)
  end

  it 'requires login' do
    get :index, params: { hydrus_collection_id: '1234' }
    expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
    expect(response).to redirect_to(new_user_session_path)
  end

  context 'as an authenticated user' do
    let(:user) { create :archivist1 }

    before do
      sign_in(user)
    end

    it "restricts access to users who shouldn't be able to view datastreams" do
      mock_coll = double('HydrusCollection', hydrus_class_to_s: 'Collection')
      expect(mock_coll).not_to receive(:"current_user=")
      expect(ActiveFedora::Base).not_to receive(:find)
      @ability.cannot :view_datastreams, '1234'

      get :index, params: { hydrus_collection_id: '1234' }

      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end

    it 'assigns the given object for the given ID as the fobj instance variable' do
      mock_coll = double('HydrusCollection', hydrus_class_to_s: 'Collection')
      expect(mock_coll).to receive(:"current_user=")
      allow(ActiveFedora::Base).to receive(:find).and_return(mock_coll)
      @ability.can :view_datastreams, '1234'

      get :index, params: { hydrus_collection_id: '1234' }

      expect(response).to be_successful
      expect(assigns(:fobj)).to eq(mock_coll)
    end
  end
end
