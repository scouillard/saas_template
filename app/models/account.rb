class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro", enterprise: "enterprise" }
  enum :subscription_status, {
    none: "none",
    active: "active",
    past_due: "past_due",
    cancelled: "cancelled",
    trialing: "trialing"
  }, prefix: true

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :account_invitations, dependent: :destroy

  def subscribed?
    subscription_status_active? || subscription_status_trialing?
  end

  def plan_details
    Plan.find_by(id: plan)
  end
end
