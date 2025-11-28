class AccountInvitation < ApplicationRecord
  belongs_to :account
  belongs_to :inviter, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, uniqueness: true
  validates :expires_at, presence: true
  validates :email, uniqueness: { scope: :account_id, conditions: -> { pending } }

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }

  def pending?
    accepted_at.nil? && !expired?
  end

  def accepted?
    accepted_at.present?
  end

  def expired?
    accepted_at.nil? && expires_at <= Time.current
  end

  def accept!(user)
    transaction do
      update!(accepted_at: Time.current)
      account.memberships.create!(user: user, role: :member)
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end
end
