class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :lockable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"

  before_destroy :verify_can_delete_account

  def sole_owner_of_accounts
    @sole_owner_of_accounts ||= memberships.owner.includes(:account).select do |m|
      m.account.memberships.count > 1
    end.map(&:account)
  end

  def can_delete_account?
    sole_owner_of_accounts.empty?
  end

  after_create_commit :create_default_account
  after_create_commit :send_welcome_notification

  def self.find_or_create_from_oauth(auth)
    email = auth.info.email.downcase

    # First, try to find by provider and uid (returning user via OAuth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Check if a user exists with this email (signed up via email/password or different provider)
    existing_user = find_by(email: email)

    if existing_user
      # Link OAuth credentials to existing account
      existing_user.update!(provider: auth.provider, uid: auth.uid)
      existing_user
    else
      # Create new user
      create!(
        email: email,
        name: auth.info.name,
        provider: auth.provider,
        uid: auth.uid,
        password: SecureRandom.hex(16),
        confirmed_at: Time.current
      )
    end
  end

  private

  def verify_can_delete_account
    unless can_delete_account?
      errors.add(:base, "Cannot delete account while sole owner of a team with other members")
      throw(:abort)
    end
  end

  def create_default_account
    default_name = name.presence || email.split("@").first.titleize
    account = Account.create!(name: "#{default_name}'s Team")
    memberships.create!(account: account, role: :owner)
  end

  def send_welcome_notification
    WelcomeNotifier.with(record: self).deliver(self)
  end
end
