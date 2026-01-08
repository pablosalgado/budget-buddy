require 'rails_helper'

RSpec.describe 'Registrations', type: :request do
  describe 'GET /registration/new' do
    it 'returns successful response' do
      get new_registration_path
      expect(response).to have_http_status(:success)
    end

    it 'does not require authentication' do
      get new_registration_path
      expect(response).not_to redirect_to(new_session_path)
    end
  end

  describe 'POST /registration' do
    let(:valid_attributes) do
      {
        user: {
          email_address: 'newuser@example.com',
          password: 'Password123',
          password_confirmation: 'Password123'
        }
      }
    end

    context 'with valid attributes' do
      it 'creates a new user' do
        expect {
          post registration_path, params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it 'creates a session for the new user' do
        expect {
          post registration_path, params: valid_attributes
        }.to change(Session, :count).by(1)
      end

      it 'signs in the new user' do
        post registration_path, params: valid_attributes
        expect(cookies.signed[:session_id]).to be_present
      end

      it 'redirects to root path' do
        post registration_path, params: valid_attributes
        expect(response).to redirect_to(root_path)
      end

      it 'shows welcome notice' do
        post registration_path, params: valid_attributes
        expect(flash[:notice]).to eq('Welcome! Your account has been created.')
      end

      it 'normalizes email address' do
        attrs = valid_attributes.dup
        attrs[:user][:email_address] = '  NEWUSER@EXAMPLE.COM  '
        post registration_path, params: attrs
        user = User.last
        expect(user.email_address).to eq('newuser@example.com')
      end
    end

    context 'with invalid email' do
      it 'does not create a user' do
        invalid_attrs = valid_attributes.dup
        invalid_attrs[:user][:email_address] = 'invalid-email'
        
        expect {
          post registration_path, params: invalid_attrs
        }.not_to change(User, :count)
      end

      it 'renders new template with errors' do
        invalid_attrs = valid_attributes.dup
        invalid_attrs[:user][:email_address] = 'invalid-email'
        
        post registration_path, params: invalid_attrs
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('prohibited this account from being saved')
      end
    end

    context 'with duplicate email' do
      before do
        create(:user, email_address: 'existing@example.com')
      end

      it 'does not create a user' do
        duplicate_attrs = valid_attributes.dup
        duplicate_attrs[:user][:email_address] = 'existing@example.com'
        
        expect {
          post registration_path, params: duplicate_attrs
        }.not_to change(User, :count)
      end

      it 'shows uniqueness error' do
        duplicate_attrs = valid_attributes.dup
        duplicate_attrs[:user][:email_address] = 'existing@example.com'
        
        post registration_path, params: duplicate_attrs
        expect(response.body).to include('Email address has already been taken')
      end
    end

    context 'with weak password' do
      it 'rejects password without uppercase' do
        weak_attrs = valid_attributes.dup
        weak_attrs[:user][:password] = 'password123'
        weak_attrs[:user][:password_confirmation] = 'password123'
        
        expect {
          post registration_path, params: weak_attrs
        }.not_to change(User, :count)
      end

      it 'rejects password without lowercase' do
        weak_attrs = valid_attributes.dup
        weak_attrs[:user][:password] = 'PASSWORD123'
        weak_attrs[:user][:password_confirmation] = 'PASSWORD123'
        
        expect {
          post registration_path, params: weak_attrs
        }.not_to change(User, :count)
      end

      it 'rejects password without digit' do
        weak_attrs = valid_attributes.dup
        weak_attrs[:user][:password] = 'Password'
        weak_attrs[:user][:password_confirmation] = 'Password'
        
        expect {
          post registration_path, params: weak_attrs
        }.not_to change(User, :count)
      end

      it 'rejects password shorter than 8 characters' do
        weak_attrs = valid_attributes.dup
        weak_attrs[:user][:password] = 'Pass1'
        weak_attrs[:user][:password_confirmation] = 'Pass1'
        
        expect {
          post registration_path, params: weak_attrs
        }.not_to change(User, :count)
      end
    end

    context 'with mismatched password confirmation' do
      it 'does not create a user' do
        mismatched_attrs = valid_attributes.dup
        mismatched_attrs[:user][:password_confirmation] = 'DifferentPassword123'
        
        expect {
          post registration_path, params: mismatched_attrs
        }.not_to change(User, :count)
      end

      it 'shows confirmation error' do
        mismatched_attrs = valid_attributes.dup
        mismatched_attrs[:user][:password_confirmation] = 'DifferentPassword123'
        
        post registration_path, params: mismatched_attrs
        expect(response.body).to include("Password confirmation doesn't match")
      end
    end

    context 'rate limiting' do
      it 'allows up to 10 registration attempts within 3 minutes' do
        10.times do |i|
          attrs = valid_attributes.dup
          attrs[:user][:email_address] = "user#{i}@example.com"
          post registration_path, params: attrs
          expect(response).to have_http_status(:found) # redirect
        end
      end
    end
  end
end
