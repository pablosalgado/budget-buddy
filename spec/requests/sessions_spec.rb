require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'GET /session/new' do
    it 'returns successful response' do
      get new_session_path
      expect(response).to have_http_status(:success)
    end

    it 'does not require authentication' do
      get new_session_path
      expect(response).not_to redirect_to(new_session_path)
    end
  end

  describe 'POST /session' do
    let(:user) { create(:user, password: 'Password123') }

    context 'with valid credentials' do
      it 'creates a new session' do
        expect {
          post session_path, params: { email_address: user.email_address, password: 'Password123' }
        }.to change(Session, :count).by(1)
      end

      it 'sets session cookie' do
        post session_path, params: { email_address: user.email_address, password: 'Password123' }
        expect(cookies.signed[:session_id]).to be_present
      end

      it 'redirects to root path' do
        post session_path, params: { email_address: user.email_address, password: 'Password123' }
        expect(response).to redirect_to(root_url)
      end

      it 'stores user agent and IP address' do
        post session_path, params: { email_address: user.email_address, password: 'Password123' },
             headers: { 'User-Agent' => 'TestAgent/1.0', 'REMOTE_ADDR' => '127.0.0.1' }
        
        session = Session.last
        expect(session.user_agent).to eq('TestAgent/1.0')
        expect(session.ip_address).to eq('127.0.0.1')
      end
    end

    context 'with invalid email' do
      it 'does not create a session' do
        expect {
          post session_path, params: { email_address: 'wrong@example.com', password: 'Password123' }
        }.not_to change(Session, :count)
      end

      it 'redirects back to sign in' do
        post session_path, params: { email_address: 'wrong@example.com', password: 'Password123' }
        expect(response).to redirect_to(new_session_path)
      end

      it 'sets an error alert' do
        post session_path, params: { email_address: 'wrong@example.com', password: 'Password123' }
        expect(flash[:alert]).to eq('Try another email address or password.')
      end
    end

    context 'with invalid password' do
      it 'does not create a session' do
        expect {
          post session_path, params: { email_address: user.email_address, password: 'WrongPassword' }
        }.not_to change(Session, :count)
      end

      it 'redirects back to sign in' do
        post session_path, params: { email_address: user.email_address, password: 'WrongPassword' }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'rate limiting' do
      it 'allows up to 10 attempts within 3 minutes' do
        10.times do
          post session_path, params: { email_address: user.email_address, password: 'WrongPassword' }
          expect(response).to have_http_status(:found) # redirect
        end
      end
    end
  end

  describe 'DELETE /session' do
    let(:user) { create(:user) }
    let(:session_record) { create(:session, user: user) }

    before do
      cookies.signed[:session_id] = session_record.id
    end

    it 'destroys the session' do
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end

    it 'clears the session cookie' do
      delete session_path
      expect(cookies.signed[:session_id]).to be_nil
    end

    it 'redirects to sign in page' do
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end

    it 'has see_other status' do
      delete session_path
      expect(response).to have_http_status(:see_other)
    end
  end
end
