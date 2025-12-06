class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, raise: false

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError
      head :bad_request
      return
    end

    handle_event(event)

    head :ok
  end

  private

  def handle_event(event)
    case event.type
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    end
  end

  def handle_subscription_updated(subscription)
    account = Account.find_by(stripe_subscription_id: subscription.id)
    return unless account

    if subscription.cancel_at_period_end
      account.update!(
        subscription_status: :canceling,
        current_period_ends_at: Time.at(subscription.current_period_end)
      )
    else
      account.update!(
        subscription_status: subscription.status,
        current_period_ends_at: Time.at(subscription.current_period_end)
      )
    end
  end

  def handle_subscription_deleted(subscription)
    account = Account.find_by(stripe_subscription_id: subscription.id)
    return unless account

    account.update!(
      subscription_status: :canceled,
      plan: :free,
      stripe_subscription_id: nil,
      current_period_ends_at: nil
    )
  end
end
