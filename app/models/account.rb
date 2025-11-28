class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro", enterprise: "enterprise" }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
end
