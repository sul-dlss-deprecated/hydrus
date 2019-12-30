require 'spec_helper'

RSpec.describe HydrusItemsController, type: :controller do
  # SHOW ACTION.
  describe 'Show Action', integration: true do
    it 'should redirect when not logged in' do
      @pid = 'druid:bb123bb1234'
      get :show, params: { id: @pid }
      expect(response).to redirect_to new_user_session_path
    end
  end

  describe 'New Action', integration: true do
    let(:user) { create :user }
    let(:archivist1) { create :archivist1 }
    it 'should restrict access to non authed user' do
      sign_in(user)
      get :new, params: { collection: 'druid:bb000bb0003' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
    end

    it 'should redirect w/ a flash error when no collection has been provided' do
      sign_in(archivist1)
      get :new
      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to match(/You cannot create an item without specifying a collection./)
    end
  end

  describe 'Update Action' do
    let(:user) { create :archivist1 }
    describe('File upload', integration: true) do
      before(:all) do
        @pid = 'druid:bb123bb1234'
        @file = fixture_file_upload('/../../spec/fixtures/files/fixture.html', 'text/html')
      end

      it 'should update the file successfully' do
        sign_in(user)
        put :update, params: { :id => @pid, 'files' => [@file] }
        expect(response).to redirect_to(hydrus_item_path(@pid))
        expect(flash[:notice]).to match(/Your changes have been saved/)
        expect(flash[:notice]).to match(/&#39;fixture.html&#39; uploaded/)
        expect(Hydrus::Item.find(@pid).files.map { |file| file.filename }.include?('fixture.html')).to be_truthy
      end
    end
  end

  describe '#index' do
    let(:user) { create :user }

    context 'when not signed in' do
      it 'redirects with a flash message' do
        get :index, params: { hydrus_collection_id: '1234' }
        expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in as an authorized user' do
      let(:mock_coll) { instance_double(Hydrus::Collection, pid: '1234') }
      let(:presenter_list) { instance_double(Array) }

      before do
        sign_in(user)
        expect(mock_coll).to receive(:"current_user=")
        allow(Hydrus::Collection).to receive(:find).and_return(mock_coll)
        allow(controller).to receive(:item_presenters_for_collection).and_return(presenter_list)
        controller.current_ability.can :read, mock_coll
      end

      it 'returns the collection requested via the hydrus_collection_id parameter and assign it to the fobj instance variable' do
        get :index, params: { hydrus_collection_id: '1234' }
        expect(response).to be_successful
        expect(assigns(:fobj)).to eq(mock_coll)
        expect(assigns(:items)).to eq(presenter_list)
      end
    end

    context 'when signed in as a user who is not authorized' do
      before do
        sign_in(user)
        allow(Hydrus::Collection).to receive(:find).and_return(double('', :current_user= => nil))
      end

      it 'restricts access to authorized users' do
        get :index, params: { hydrus_collection_id: '12345' }
        expect(flash[:alert]).to eq('You are not authorized to access this page.')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#publish_directly', integration: true do
    let(:user) { create :user }
    it 'raises an exception if the user lacks the required permissions' do
      sign_in(user)
      post :publish_directly, params: { id: 'druid:bb123bb1234' }
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end
  end

  describe '#submit_for_approval', integration: true do
    let(:user) { create :user }
    it 'raises an exception if the user lacks the required permissions' do
      sign_in(user)
      post :submit_for_approval, params: { id: 'druid:bb123bb1234' }
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end
  end

  describe '#approve', integration: true do
    let(:user) { create :user }
    it 'raises an exception if the user lacks the required permissions' do
      sign_in(user)
      post :approve, params: { id: 'druid:bb123bb1234' }
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end
  end

  describe '#disapprove', integration: true do
    let(:user) { create :user }
    it 'raises an exception if the user lacks the required permissions' do
      sign_in(user)
      post :disapprove, params: { id: 'druid:bb123bb1234' }
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end
  end

  describe '#resubmit', integration: true do
    let(:user) { create :user }
    it 'raises an exception if the user lacks the required permissions' do
      sign_in(user)
      post :resubmit, params: { id: 'druid:bb123bb1234' }
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end
  end

  describe '#open_new_version', integration: true do
    let(:user) { create :user }
    it 'raises an exception if the user lacks the required permissions' do
      sign_in(user)
      post :open_new_version, params: { id: 'druid:bb123bb1234' }
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
      expect(response).to redirect_to(root_path)
    end
  end
end
