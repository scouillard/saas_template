module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      event = construct_event
      return head :bad_request if event.nil?

      handle_event(event)
      head :ok
    end

    private

    def handle_event(event)
      case event.type
      when "checkout.session.completed" then handle_checkout_session_completed(event)
      when "customer.subscription.updated" then handle_subscription_updated(event)
      when "customer.subscription.deleted" then handle_subscription_deleted(event)
      when "invoice.payment_succeeded" then handle_invoice_payment_succeeded(event)
      when "invoice.payment_failed" then handle_invoice_payment_failed(event)
      else Rails.logger.info("Unhandled Stripe webhook event: #{event.type}")
      end
    end

    def construct_event
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) ||
        ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)

      Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.error("Stripe webhook error: #{e.message}")
      nil
    end

    def handle_checkout_session_completed(event)
      session = event.data.object
      customer_id = session.customer
      subscription_id = session.subscription

      account = Account.find_by(stripe_customer_id: customer_id)
      return unless account

      subscription = Stripe::Subscription.retrieve(subscription_id)
      account.sync_subscription(subscription)
    end

    def handle_subscription_updated(event)
      subscription = event.data.object
      customer_id = subscription.customer

      account = Account.find_by(stripe_customer_id: customer_id)
      return unless account

      account.sync_subscription(subscription)
    end

    def handle_subscription_deleted(event)
      subscription = event.data.object
      customer_id = subscription.customer

      account = Account.find_by(stripe_customer_id: customer_id)
      return unless account

      account.cancel_subscription(subscription)
    end

    def handle_invoice_payment_succeeded(event)
      invoice = event.data.object
      customer_id = invoice.customer
      subscription_id = invoice.subscription

      return unless subscription_id

      account = Account.find_by(stripe_customer_id: customer_id)
      return unless account

      subscription = Stripe::Subscription.retrieve(subscription_id)
      account.update_billing_period(subscription)
    end

    def handle_invoice_payment_failed(event)
      invoice = event.data.object
      customer_id = invoice.customer

      account = Account.find_by(stripe_customer_id: customer_id)
      return unless account

      account.update!(subscription_status: :past_due)
    end
  end
end
