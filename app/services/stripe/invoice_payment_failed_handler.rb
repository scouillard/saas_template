module Stripe
  class InvoicePaymentFailedHandler
    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
      @invoice = event.data.object
    end

    def call
      account = ::Account.find_by(stripe_customer_id: @invoice.customer)
      return false unless account

      return true if account.subscription_status == "past_due"

      account.update!(subscription_status: "past_due")

      Rails.logger.info("Payment failed for account #{account.id}, invoice #{@invoice.id}")

      notify_owner(account)

      true
    rescue StandardError => e
      Rails.logger.error("InvoicePaymentFailedHandler error: #{e.message}")
      false
    end

    private

    def notify_owner(account)
      return unless account.owner

      PaymentFailedNotifier.with(account: account).deliver(account.owner)
    end
  end
end
