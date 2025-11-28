class Account < ApplicationRecord
  enum :plan, { free: "free" }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  validates :name, presence: true
end
