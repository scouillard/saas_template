class AccountInvitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User", foreign_key: :inviter_id

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :email, uniqueness: { scope: :account_id, message: "has already been invited to this account" }

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  def pending?
    accepted_at.nil? && expires_at > Time.current
  end

  def expired?
    accepted_at.nil? && expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    return false unless pending?

    transaction do
      update!(accepted_at: Time.current)
      account.memberships.create!(user: user, role: :member)
    end

    true
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end
end
