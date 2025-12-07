module Stripe
  class SubscriptionDeletedHandler
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

      return true if account.subscription_status == "canceled"

      account.update!(subscription_status: "canceled")
      account.downgrade_to_free!

      Rails.logger.info("Subscription #{@subscription.id} canceled for account #{account.id}")

      notify_owner(account)

      true
    rescue StandardError => e
      Rails.logger.error("SubscriptionDeletedHandler error: #{e.message}")
      false
    end

    private

    def notify_owner(account)
      return unless account.owner

      SubscriptionCanceledNotifier.with(account: account).deliver(account.owner)
    end
  end
end
