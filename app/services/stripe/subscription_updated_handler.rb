module Stripe
  class SubscriptionUpdatedHandler
    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
      @subscription = event.data.object
    end

    def call
      account = ::Account.find_by(stripe_subscription_id: @subscription.id)
      return false unless account

      account.update_subscription_from_stripe!(@subscription)

      Rails.logger.info(
        "Subscription #{@subscription.id} updated to status: #{@subscription.status}"
      )

      true
    rescue StandardError => e
      Rails.logger.error("SubscriptionUpdatedHandler error: #{e.message}")
      false
    end
  end
end
