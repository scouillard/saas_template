module Stripe
  class SubscriptionDeletedHandler
    def initialize(event)
      @event = event
      @subscription = event.data.object
    end

    def call
      account = find_account
      return unless account

      account.update!(
        subscription_status: "cancelled",
        subscription_ends_at: Time.zone.at(@subscription.current_period_end)
      )

      Rails.logger.info("[Stripe] Subscription deleted for account #{account.id}")
      account
    end

    private

    def find_account
      ::Account.find_by(stripe_subscription_id: @subscription.id)
    end
  end
end
