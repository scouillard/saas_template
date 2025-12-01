module Api
  class StripeController < ActionController::API
    def webhook
      event = construct_event
      return head :bad_request unless event

      handle_event(event)
      head :ok
    end

    private

    def construct_event
      Stripe::Webhook.construct_event(
        request.body.read,
        request.env["HTTP_STRIPE_SIGNATURE"],
        Rails.application.credentials.dig(:stripe, :webhook_secret)
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      nil
    end

    def handle_event(event)
      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      end
    end

    def handle_checkout_completed(session)
      account = Account.find_by(id: session.client_reference_id)
      return unless account

      account.update!(
        stripe_customer_id: session.customer,
        stripe_subscription_id: session.subscription,
        plan: :pro,
        subscription_status: "active",
        subscription_started_at: Time.current
      )
    end

    def handle_subscription_updated(subscription)
      account = Account.find_by(stripe_subscription_id: subscription.id)
      return unless account

      account.update!(
        subscription_status: subscription.status,
        current_period_ends_at: Time.at(subscription.current_period_end)
      )
    end

    def handle_subscription_deleted(subscription)
      account = Account.find_by(stripe_subscription_id: subscription.id)
      return unless account

      account.update!(
        plan: :free,
        stripe_subscription_id: nil,
        subscription_status: nil,
        subscription_ends_at: Time.current
      )
    end

    def handle_payment_failed(invoice)
      account = Account.find_by(stripe_customer_id: invoice.customer)
      return unless account

      account.update!(subscription_status: "past_due")
    end
  end
end
