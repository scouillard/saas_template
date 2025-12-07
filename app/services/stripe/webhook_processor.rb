module Stripe
  class WebhookProcessor
    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      case @event.type
      when "invoice.payment_failed"
        Stripe::InvoicePaymentFailedHandler.call(@event)
      when "customer.subscription.updated"
        Stripe::SubscriptionUpdatedHandler.call(@event)
      when "customer.subscription.deleted"
        Stripe::SubscriptionDeletedHandler.call(@event)
      else
        Rails.logger.info("Unhandled Stripe event: #{@event.type}")
        true
      end
    end
  end
end
