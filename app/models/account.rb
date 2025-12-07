class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro", enterprise: "enterprise" }, prefix: true
  enum :subscription_status, {
    incomplete: "incomplete",
    incomplete_expired: "incomplete_expired",
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

  def sync_subscription(subscription)
    update!(subscription_attributes(subscription))
  end

  def cancel_subscription(subscription)
    update!(
      subscription_status: :canceled,
      plan: :free,
      subscription_ends_at: Time.zone.at(subscription.ended_at || subscription.current_period_end)
    )
  end

  def update_billing_period(subscription)
    update!(
      subscription_status: :active,
      current_period_ends_at: Time.zone.at(subscription.current_period_end)
    )
  end

  def determine_plan_from_price_id(price_id)
    price_id_to_plan[price_id]
  end

  private

  def price_id_to_plan
    {
      ENV.fetch("STRIPE_PRO_PRICE_ID", nil) => "pro",
      ENV.fetch("STRIPE_ENTERPRISE_PRICE_ID", nil) => "enterprise"
    }
  end

  def subscription_attributes(subscription)
    price_id = subscription.items.data.first&.price&.id
    {
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      plan: determine_plan_from_price_id(price_id) || plan,
      subscription_started_at: Time.zone.at(subscription.start_date),
      current_period_ends_at: Time.zone.at(subscription.current_period_end),
      subscription_ends_at: subscription.cancel_at ? Time.zone.at(subscription.cancel_at) : nil
    }
  end
end
