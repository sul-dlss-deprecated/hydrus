# frozen_string_literal: true
require 'spec_helper'

describe SessionsController, type: :controller do
  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'routes' do
    it 'should properly define login' do
      pending
      expect(webauth_login_path).to eq('/users/auth/webauth')
      assert_routing({ path: 'users/auth/webauth', method: :get },
        { controller: 'sessions', action: 'new' })
    end
    it 'should properly define logout' do
      expect(webauth_logout_path).to eq('/users/auth/webauth/logout')
      assert_routing({ path: 'users/auth/webauth/logout', method: :get },
        { controller: 'sessions', action: 'destroy_webauth' })
    end
  end

  describe 'destroy_webauth' do
    before(:each) do
      request.env['HTTP_REFERER'] = '/somepath'
    end
    it 'should set the flash message letting the user know they have been logged out' do
      get :destroy_webauth
      expect(flash[:notice]).to eq('You have successfully logged out of WebAuth.')
      expect(response).to redirect_to('/')
    end
    it 'should not set the flash message if the user is still logged into WebAuth.' do
      request.env['WEBAUTH_USER'] = 'not-a-real-user'
      get :destroy_webauth
      expect(flash[:notice]).to be_nil
      expect(response).to redirect_to('/')
    end
    it 'should redirect back to home page after logout' do
      get :destroy_webauth
      expect(response).to redirect_to('/')
    end
  end
end