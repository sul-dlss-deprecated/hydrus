require 'spec_helper'

describe EventsController, type: :controller do
  before :each do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    allow(controller).to receive_messages(current_ability: @ability)
  end


  it 'should require login' do
    get :index, hydrus_collection_id: '1234'
    expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
    expect(response).to redirect_to(new_user_session_path)
  end

context 'as an authenticated user' do
  before :each do
    sign_in(mock_authed_user)
  end

  it "should restrict access to users who shouldn't be able to view items" do  
    mock_coll = double('HydrusCollection', hydrus_class_to_s: 'Collection')
    expect(mock_coll).to receive(:"current_user=")
    allow(ActiveFedora::Base).to receive(:find).and_return(mock_coll)
    @ability.cannot :read, mock_coll

    get :index, hydrus_collection_id: '1234'
    
    expect(flash[:alert]).to eq('You are not authorized to access this page.')
    expect(response).to redirect_to(root_path)
  end

  it 'should assign the given object for the given ID as the fobj instance variable' do
    mock_coll = double('HydrusCollection', hydrus_class_to_s: 'Collection')
    expect(mock_coll).to receive(:"current_user=")
    allow(ActiveFedora::Base).to receive(:find).and_return(mock_coll)
    @ability.can :read, mock_coll

    get :index, hydrus_collection_id: '1234'
    
    expect(response).to be_success
    expect(assigns(:fobj)).to eq(mock_coll)
  end
end
end
