class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships

  def self.find_or_create_from_oauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.password = SecureRandom.hex(16)
    end
  end
end
