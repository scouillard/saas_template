module Stripe
  class InvoicePaidHandler
    def initialize(event)
      @event = event
      @invoice = event.data.object
    end

    def call
      account = find_account
      return unless account

      subscription_id = @invoice.subscription
      return unless subscription_id

      account.update!(
        subscription_status: "active",
        subscription_started_at: account.subscription_started_at || Time.current
      )

      Rails.logger.info("[Stripe] Invoice paid for account #{account.id}")
      account
    end

    private

    def find_account
      ::Account.find_by(stripe_customer_id: @invoice.customer)
    end
  end
end
