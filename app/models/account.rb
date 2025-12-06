class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro", enterprise: "enterprise" }, prefix: true
  enum :subscription_status, {
    incomplete: "incomplete",
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    unpaid: "unpaid"
  }, prefix: true

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :account_invitations, dependent: :destroy

  def subscription_active?
    subscription_status_active? || subscription_status_trialing?
  end

  def plan_name
    Plan.find_by(id: plan)&.name || plan&.titleize
  end
end
