require 'rails_helper'

RSpec.describe Authentication, type: :request do
  # Create a test controller to test the authentication concern
  controller(ApplicationController) do
    def index
      render plain: "Protected content"
    end

    def public_action
      render plain: "Public content"
    end
  end

  before do
    Rails.application.routes.draw do
      get '/test' => 'anonymous#index'
      get '/test/public' => 'anonymous#public_action'
      resource :session
    end
  end

  after do
    Rails.application.reload_routes!
  end

  describe 'authentication requirement' do
    context 'when not authenticated' do
      it 'redirects to sign in page' do
        get '/test'
        expect(response).to redirect_to(new_session_path)
      end

      it 'stores return URL' do
        get '/test'
        expect(session[:return_to_after_authenticating]).to eq('http://www.example.com/test')
      end
    end

    context 'when authenticated' do
      let(:user) { create(:user) }
      let(:user_session) { create(:session, user: user) }

      before do
        cookies.signed[:session_id] = user_session.id
      end

      it 'allows access to protected content' do
        get '/test'
        expect(response).to have_http_status(:success)
        expect(response.body).to eq('Protected content')
      end

      it 'sets current user' do
        get '/test'
        expect(controller.send(:authenticated?)).to be true
      end
    end
  end

  describe 'after authentication redirect' do
    let(:user) { create(:user, password: 'Password123') }

    it 'redirects to stored URL after sign in' do
      get '/test'
      post session_path, params: { email_address: user.email_address, password: 'Password123' }
      expect(response).to redirect_to('http://www.example.com/test')
    end

    it 'redirects to root if no stored URL' do
      post session_path, params: { email_address: user.email_address, password: 'Password123' }
      expect(response).to redirect_to(root_url)
    end
  end
end
