class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro" }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :account_invitations, dependent: :destroy
end
