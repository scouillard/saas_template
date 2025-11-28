class AccountInvitation < ApplicationRecord
  EXPIRATION_DAYS = 7

  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  alias_method :inviter, :invited_by
  alias_method :inviter=, :invited_by=

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :email, uniqueness: { scope: :account_id, message: "has already been invited to this account" }

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  def pending?
    accepted_at.nil? && !expired?
  end

  def accepted?
    accepted_at.present?
  end

  def expired?
    Time.current > expires_at
  end

  def accept!(user)
    raise "Invitation has already been accepted" if accepted?
    raise "Invitation has expired" if expired?

    membership = account.memberships.create!(user: user, role: :member)
    update!(accepted_at: Time.current)
    membership
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= EXPIRATION_DAYS.days.from_now
  end
end
