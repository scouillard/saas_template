class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro", enterprise: "enterprise" }, prefix: true
  enum :subscription_status, {
    incomplete: "incomplete",
    incomplete_expired: "incomplete_expired",
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    unpaid: "unpaid",
    canceling: "canceling"
  }, prefix: true

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :account_invitations, dependent: :destroy

  scope :past_due, -> { where(subscription_status: "past_due") }
  scope :canceled, -> { where(subscription_status: "canceled") }

  def subscription_active?
    subscription_status_active? || subscription_status_trialing?
  end

  def subscription_canceling?
    subscription_status_canceling?
  end

  def can_reactivate?
    subscription_canceling? && current_period_ends_at&.future?
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

  def current_plan
    Plan.find_by(id: plan)
  end

  def upgrading_to?(plan_id)
    target_plan = Plan.find_by(id: plan_id.to_s)
    current = current_plan
    return false unless target_plan && current

    target_plan.monthly_price > current.monthly_price
  end

  def downgrading_to?(plan_id)
    target_plan = Plan.find_by(id: plan_id.to_s)
    current = current_plan
    return false unless target_plan && current

    target_plan.monthly_price < current.monthly_price
  end

  def can_change_plan?
    subscription_active? && stripe_subscription_id.present?
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
    Plan.all.find { |p| [ p.stripe_monthly_price_id, p.stripe_annual_price_id ].include?(price_id) }&.id || price_id_to_plan[price_id]
  end

  def billing_interval
    return nil unless stripe_subscription_id.present?
    determine_interval_from_price_id(current_stripe_price_id)
  end

  def current_stripe_price_id
    return nil unless stripe_subscription_id.present?
    current = current_plan
    return nil unless current

    current.stripe_monthly_price_id || current.stripe_annual_price_id
  end

  def determine_interval_from_price_id(price_id)
    return nil if price_id.blank?

    Plan.all.each do |p|
      return "monthly" if p.stripe_monthly_price_id == price_id
      return "annual" if p.stripe_annual_price_id == price_id
    end
    nil
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
