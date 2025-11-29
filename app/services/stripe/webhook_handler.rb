module Stripe
  class WebhookHandler
    HANDLERS = {
      "checkout.session.completed" => CheckoutCompletedHandler,
      "customer.subscription.created" => SubscriptionCreatedHandler,
      "customer.subscription.updated" => SubscriptionUpdatedHandler,
      "customer.subscription.deleted" => SubscriptionDeletedHandler,
      "invoice.paid" => InvoicePaidHandler,
      "invoice.payment_failed" => InvoicePaymentFailedHandler
    }.freeze

    def initialize(event)
      @event = event
    end

    def call
      handler_class = HANDLERS[@event.type]
      return false unless handler_class

      Rails.logger.info("[Stripe] Processing #{@event.type} event: #{@event.id}")
      handler_class.new(@event).call
      true
    end
  end
end
