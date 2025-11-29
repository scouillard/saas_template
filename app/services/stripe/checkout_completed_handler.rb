module Stripe
  class CheckoutCompletedHandler
    def initialize(event)
      @event = event
      @session = event.data.object
    end

    def call
      account = find_account
      return unless account

      account.update!(
        stripe_customer_id: @session.customer,
        stripe_subscription_id: @session.subscription
      )

      Rails.logger.info("[Stripe] Checkout completed for account #{account.id}")
      account
    end

    private

    def find_account
      account_id = @session.client_reference_id
      return nil unless account_id

      ::Account.find_by(id: account_id)
    end
  end
end
