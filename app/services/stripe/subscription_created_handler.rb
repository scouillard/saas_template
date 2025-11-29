module Stripe
  class SubscriptionCreatedHandler
    def initialize(event)
      @event = event
      @subscription = event.data.object
    end

    def call
      account = find_account
      return unless account

      account.update!(
        stripe_subscription_id: @subscription.id,
        subscription_status: map_status(@subscription.status),
        subscription_started_at: Time.zone.at(@subscription.current_period_start),
        subscription_ends_at: Time.zone.at(@subscription.current_period_end),
        stripe_price_id: price_id,
        plan: plan_slug
      )

      Rails.logger.info("[Stripe] Subscription created for account #{account.id}")
      account
    end

    private

    def find_account
      ::Account.find_by(stripe_customer_id: @subscription.customer)
    end

    def price_id
      @subscription.items.data.first&.price&.id
    end

    def plan_slug
      ::Plan.all.find { |p| [ p.stripe_monthly_price_id, p.stripe_annual_price_id ].include?(price_id) }&.id || "free"
    end

    def map_status(stripe_status)
      case stripe_status
      when "active" then "active"
      when "trialing" then "trialing"
      when "past_due" then "past_due"
      when "canceled", "unpaid" then "cancelled"
      else "none"
      end
    end
  end
end
