class Account < ApplicationRecord
  enum :plan, { free: "free", pro: "pro", business: "business" }
  enum :subscription_status, { none: "none", active: "active", past_due: "past_due", canceled: "canceled" },
       prefix: :subscription

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  def create_stripe_customer(user)
    return stripe_customer_id if stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: user.email,
      name: name || user.name,
      metadata: { account_id: id }
    )
    update!(stripe_customer_id: customer.id)
    customer.id
  end

  def active_subscription?
    subscription_active? && stripe_subscription_id.present?
  end

  def cancel_subscription
    return unless stripe_subscription_id.present?

    Stripe::Subscription.update(stripe_subscription_id, cancel_at_period_end: true)
    update!(subscription_status: :canceled)
  end
end
