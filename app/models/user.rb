class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Validations
  validates :email_address, presence: true, 
                           uniqueness: { case_sensitive: false },
                           format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validate :password_complexity, if: -> { password.present? }

  # Password reset token
  def password_reset_token
    signed_id(purpose: "password_reset", expires_in: 24.hours)
  end

  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: "password_reset")
  end

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/[a-z]/) && password.match?(/[A-Z]/) && password.match?(/\d/)
      errors.add(:password, "must include at least one lowercase letter, one uppercase letter, and one digit")
    end
  end
end
