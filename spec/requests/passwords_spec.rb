require 'rails_helper'

RSpec.describe 'Passwords', type: :request do
  describe 'GET /passwords/new' do
    it 'returns successful response' do
      get new_password_path
      expect(response).to have_http_status(:success)
    end

    it 'does not require authentication' do
      get new_password_path
      expect(response).not_to redirect_to(new_session_path)
    end
  end

  describe 'POST /passwords' do
    let(:user) { create(:user) }

    context 'with existing user email' do
      it 'sends password reset email' do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end

      it 'redirects to sign in page' do
        post passwords_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(new_session_path)
      end

      it 'shows success notice' do
        post passwords_path, params: { email_address: user.email_address }
        expect(flash[:notice]).to eq('Password reset instructions sent (if user with that email address exists).')
      end
    end

    context 'with non-existing user email' do
      it 'does not send email' do
        expect {
          post passwords_path, params: { email_address: 'nonexistent@example.com' }
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end

      it 'still redirects to sign in page' do
        post passwords_path, params: { email_address: 'nonexistent@example.com' }
        expect(response).to redirect_to(new_session_path)
      end

      it 'shows same success notice (security measure)' do
        post passwords_path, params: { email_address: 'nonexistent@example.com' }
        expect(flash[:notice]).to eq('Password reset instructions sent (if user with that email address exists).')
      end
    end

    context 'rate limiting' do
      it 'allows up to 10 requests within 3 minutes' do
        10.times do
          post passwords_path, params: { email_address: 'test@example.com' }
          expect(response).to have_http_status(:found) # redirect
        end
      end
    end
  end

  describe 'GET /passwords/:token/edit' do
    let(:user) { create(:user) }
    let(:token) { user.password_reset_token }

    context 'with valid token' do
      it 'returns successful response' do
        get edit_password_path(token)
        expect(response).to have_http_status(:success)
      end

      it 'does not require authentication' do
        get edit_password_path(token)
        expect(response).not_to redirect_to(new_session_path)
      end
    end

    context 'with invalid token' do
      it 'redirects to new password page' do
        get edit_password_path('invalid_token')
        expect(response).to redirect_to(new_password_path)
      end

      it 'shows error alert' do
        get edit_password_path('invalid_token')
        expect(flash[:alert]).to eq('Password reset link is invalid or has expired.')
      end
    end

    context 'with expired token' do
      it 'redirects to new password page' do
        token = user.password_reset_token
        
        travel_to(25.hours.from_now) do
          get edit_password_path(token)
          expect(response).to redirect_to(new_password_path)
        end
      end
    end
  end

  describe 'PATCH /passwords/:token' do
    let(:user) { create(:user, password: 'OldPassword123') }
    let(:token) { user.password_reset_token }

    before do
      create(:session, user: user) # Create an existing session
    end

    context 'with valid password and confirmation' do
      let(:new_password_params) do
        {
          password: 'NewPassword123',
          password_confirmation: 'NewPassword123'
        }
      end

      it 'updates the password' do
        patch password_path(token), params: new_password_params
        user.reload
        expect(user.authenticate('NewPassword123')).to eq(user)
      end

      it 'destroys all user sessions' do
        expect {
          patch password_path(token), params: new_password_params
        }.to change { user.sessions.count }.to(0)
      end

      it 'redirects to sign in page' do
        patch password_path(token), params: new_password_params
        expect(response).to redirect_to(new_session_path)
      end

      it 'shows success notice' do
        patch password_path(token), params: new_password_params
        expect(flash[:notice]).to eq('Password has been reset.')
      end
    end

    context 'with mismatched passwords' do
      let(:mismatched_params) do
        {
          password: 'NewPassword123',
          password_confirmation: 'DifferentPassword123'
        }
      end

      it 'does not update the password' do
        original_digest = user.password_digest
        patch password_path(token), params: mismatched_params
        user.reload
        expect(user.password_digest).to eq(original_digest)
      end

      it 'redirects back to edit page' do
        patch password_path(token), params: mismatched_params
        expect(response).to redirect_to(edit_password_path(token))
      end

      it 'shows error alert' do
        patch password_path(token), params: mismatched_params
        expect(flash[:alert]).to eq('Passwords did not match.')
      end
    end

    context 'with invalid token' do
      it 'redirects to new password page' do
        patch password_path('invalid_token'), params: {
          password: 'NewPassword123',
          password_confirmation: 'NewPassword123'
        }
        expect(response).to redirect_to(new_password_path)
      end
    end
  end
end
