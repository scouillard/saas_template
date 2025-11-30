module Api
  class StripeController < ActionController::API
    def webhook
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, Rails.application.credentials.dig(:stripe, :webhook_secret)
        )
      rescue JSON::ParserError, Stripe::SignatureVerificationError
        head :bad_request
        return
      end

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      end

      head :ok
    end

    private

    def handle_checkout_completed(session)
      account = Account.find_by(id: session.client_reference_id)
      return unless account

      account.update!(
        stripe_customer_id: session.customer,
        stripe_subscription_id: session.subscription,
        plan: :pro,
        subscription_started_at: Time.current
      )
    end

    def handle_subscription_deleted(subscription)
      account = Account.find_by(stripe_subscription_id: subscription.id)
      return unless account

      account.update!(
        plan: :free,
        stripe_subscription_id: nil,
        subscription_ends_at: Time.current
      )
    end
  end
end
