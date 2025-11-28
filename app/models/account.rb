class Account < ApplicationRecord
  enum :plan, { free: "free" }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, class_name: "AccountInvitation", dependent: :destroy
end
