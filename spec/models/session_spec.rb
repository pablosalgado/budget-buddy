require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      session = build(:session)
      expect(session).to be_valid
    end

    it 'requires a user' do
      session = build(:session, user: nil)
      expect(session).not_to be_valid
    end
  end

  describe 'attributes' do
    it 'can store IP address' do
      session = create(:session, ip_address: '192.168.1.1')
      expect(session.reload.ip_address).to eq('192.168.1.1')
    end

    it 'can store user agent' do
      user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      session = create(:session, user_agent: user_agent)
      expect(session.reload.user_agent).to eq(user_agent)
    end
  end
end
