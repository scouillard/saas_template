module Stripe
  class InvoicePaymentFailedHandler
    def initialize(event)
      @event = event
      @invoice = event.data.object
    end

    def call
      account = find_account
      return unless account

      subscription_id = @invoice.subscription
      return unless subscription_id

      account.update!(subscription_status: "past_due")

      Rails.logger.info("[Stripe] Invoice payment failed for account #{account.id}")
      account
    end

    private

    def find_account
      ::Account.find_by(stripe_customer_id: @invoice.customer)
    end
  end
end
