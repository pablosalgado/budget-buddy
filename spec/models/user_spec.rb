require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
    
    describe 'email format' do
      it 'accepts valid email addresses' do
        valid_emails = %w[user@example.com USER@example.COM test.user@example.co.uk]
        valid_emails.each do |email|
          user = build(:user, email_address: email)
          expect(user).to be_valid, "#{email} should be valid"
        end
      end

      it 'rejects invalid email addresses' do
        invalid_emails = %w[user@example user.example.com @example.com user@ user]
        invalid_emails.each do |email|
          user = build(:user, email_address: email)
          expect(user).not_to be_valid, "#{email} should be invalid"
        end
      end
    end

    describe 'password length' do
      it 'requires minimum 8 characters' do
        user = build(:user, password: 'Short1', password_confirmation: 'Short1')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 8 characters)')
      end

      it 'accepts passwords with 8 or more characters' do
        user = build(:user, password: 'LongPass123', password_confirmation: 'LongPass123')
        expect(user).to be_valid
      end
    end

    describe 'password complexity' do
      it 'requires at least one lowercase letter' do
        user = build(:user, password: 'PASSWORD123', password_confirmation: 'PASSWORD123')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must include at least one lowercase letter, one uppercase letter, and one digit')
      end

      it 'requires at least one uppercase letter' do
        user = build(:user, password: 'password123', password_confirmation: 'password123')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must include at least one lowercase letter, one uppercase letter, and one digit')
      end

      it 'requires at least one digit' do
        user = build(:user, password: 'Password', password_confirmation: 'Password')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must include at least one lowercase letter, one uppercase letter, and one digit')
      end

      it 'accepts passwords with lowercase, uppercase, and digit' do
        user = build(:user, password: 'Password123', password_confirmation: 'Password123')
        expect(user).to be_valid
      end
    end
  end

  describe 'email normalization' do
    it 'normalizes email to lowercase' do
      user = create(:user, email_address: 'USER@EXAMPLE.COM')
      expect(user.email_address).to eq('user@example.com')
    end

    it 'strips whitespace from email' do
      user = create(:user, email_address: '  user@example.com  ')
      expect(user.email_address).to eq('user@example.com')
    end
  end

  describe 'has_secure_password' do
    it 'authenticates with correct password' do
      user = create(:user, password: 'Password123')
      expect(user.authenticate('Password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = create(:user, password: 'Password123')
      expect(user.authenticate('WrongPassword')).to be false
    end

    it 'stores password as digest' do
      user = create(:user, password: 'Password123')
      expect(user.password_digest).not_to eq('Password123')
      expect(user.password_digest).to be_present
    end
  end

  describe '#password_reset_token' do
    it 'generates a signed token' do
      user = create(:user)
      token = user.password_reset_token
      expect(token).to be_present
      expect(token).to be_a(String)
    end

    it 'token expires after 24 hours' do
      user = create(:user)
      token = user.password_reset_token
      
      # Fast forward time to test expiration
      travel_to(25.hours.from_now) do
        expect {
          User.find_by_password_reset_token!(token)
        }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
      end
    end
  end

  describe '.find_by_password_reset_token!' do
    it 'finds user by valid token' do
      user = create(:user)
      token = user.password_reset_token
      
      found_user = User.find_by_password_reset_token!(token)
      expect(found_user).to eq(user)
    end

    it 'raises error for invalid token' do
      expect {
        User.find_by_password_reset_token!('invalid_token')
      }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
    end

    it 'raises error for expired token' do
      user = create(:user)
      token = user.password_reset_token
      
      travel_to(25.hours.from_now) do
        expect {
          User.find_by_password_reset_token!(token)
        }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
      end
    end
  end

  describe 'dependent destroy' do
    it 'destroys associated sessions when user is destroyed' do
      user = create(:user, :with_sessions)
      session_ids = user.sessions.pluck(:id)
      
      expect {
        user.destroy
      }.to change(Session, :count).by(-2)
      
      session_ids.each do |id|
        expect(Session.find_by(id: id)).to be_nil
      end
    end
  end
end
