class Membership < ApplicationRecord
  enum :role, { member: "member", admin: "admin", owner: "owner" }

  belongs_to :user
  belongs_to :account

  validates :user_id, uniqueness: { scope: :account_id }
end
