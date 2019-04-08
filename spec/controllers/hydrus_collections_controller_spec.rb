require 'spec_helper'

describe HydrusCollectionsController, type: :controller do
  describe 'Index action' do
    it "should redirect with a flash message when we're not dealing w/ a nested resource" do
      get :index
      expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'Routes and Mapping' do
    it 'maps collections show correctly' do
      expect(get: '/collections/abc').to route_to(
        controller: 'hydrus_collections',
        action: 'show',
        id: 'abc'
      )
    end

    it 'maps collections destroy_value action correctly' do
      expect(get: '/collections/abc/destroy_value').to route_to(
        controller: 'hydrus_collections',
        action: 'destroy_value',
        id: 'abc'
      )
    end

    it 'should have the destroy_hydrus_collection_value convenience url' do
      expect(destroy_hydrus_collection_value_path('123')).to match(/collections\/123\/destroy_value/)
    end

    it 'routes collections/list_all correctly' do
      expect(get: '/collections/list_all').to route_to(
        controller: 'hydrus_collections',
        action: 'list_all'
      )
    end

    it 'routes open action correctly' do
      expect(post: '/collections/open/abc123').to route_to(controller: 'hydrus_collections', action: 'open', id: 'abc123')
    end

    it 'routes close action correctly' do
      expect(post: '/collections/close/abc123').to route_to(controller: 'hydrus_collections', action: 'close', id: 'abc123')
    end
  end

  describe 'Show Action', integration: true do
    it 'redirects the user when not logged in' do
      get :show, id: 'druid:oo000oo0003'
      expect(response).to redirect_to new_user_session_path
    end
  end

  describe 'Update Action', integration: true do
    it 'does not allow a user to update an object if you do not have edit permissions' do
      sign_in(create(:user))
      put :update, id: 'druid:oo000oo0003'
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('You are not authorized to access this page.')
    end
  end

  describe 'open', integration: true do
    it 'shows a alert if user lacks required permissions' do
      sign_in(create(:user))
      post :open, id: 'druid:oo000oo0003'

      expect(flash[:alert]).to eq('You are not authorized to access this page.')
    end
  end

  describe 'close', integration: true do
    it 'gives an alert if user lacks required permissions' do
      sign_in(create(:user))
      post :close, id: 'druid:oo000oo0003'

      expect(flash[:alert]).to eq('You are not authorized to access this page.')
    end
  end

  describe 'list_all', integration: true do
    context 'when logged in' do
      let(:user) { create :archivist1 }
      before do
        sign_in(user)
      end

      it 'redirects to root url for non-admins when not in development mode' do
        get :list_all
        expect(flash[:alert]).to eq('You are not authorized to access this page.')
        expect(response).to redirect_to(root_path)
      end

      it 'renders the page for users with sufficient powers' do
        controller.current_ability.can :list_all_collections, Hydrus::Collection
        get :list_all
        expect(assigns[:all_collections]).not_to eq(nil)
        expect(response).to render_template(:list_all)
      end
    end

    context 'when not logged in' do
      it 'redirects to new session path' do
        get :list_all
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
