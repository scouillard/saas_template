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

  scope :past_due, -> { where(subscription_status: "past_due") }
  scope :canceled, -> { where(subscription_status: "canceled") }

  def subscription_active?
    subscription_status_active? || subscription_status_trialing?
  end

  def plan_name
    Plan.find_by(id: plan)&.name || plan&.titleize
  end

  def owner
    memberships.find_by(role: "owner")&.user
  end

  def past_due?
    subscription_status == "past_due"
  end

  def canceled?
    subscription_status == "canceled"
  end

  def active_subscription?
    subscription_status == "active"
  end

  def downgrade_to_free!
    update!(
      plan: "free",
      stripe_subscription_id: nil,
      subscription_status: nil,
      current_period_ends_at: nil
    )
  end

  def update_subscription_from_stripe!(stripe_subscription)
    update!(
      subscription_status: stripe_subscription.status,
      current_period_ends_at: Time.zone.at(stripe_subscription.current_period_end)
    )
  end
end
