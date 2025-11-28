class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook
  before_action :authenticate_user!, except: :webhook

  ALLOWED_PRICES = [ ENV["STRIPE_PRICE_MONTHLY"], ENV["STRIPE_PRICE_YEARLY"] ].freeze

  def checkout_session
    price_id = params[:price_id]
    return head :bad_request unless ALLOWED_PRICES.include?(price_id)

    session = Stripe::Checkout::Session.create(
      customer_email: current_user.email,
      mode: "subscription",
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: stripe_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: stripe_cancel_url,
      metadata: { account_id: current_account.id }
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    return redirect_to plan_path, alert: "Invalid session" if params[:session_id].blank?

    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    return redirect_to plan_path, alert: "Invalid session" unless session.metadata.account_id == current_account.id.to_s

    subscription = Stripe::Subscription.retrieve(session.subscription)

    current_account.update!(
      stripe_customer_id: session.customer,
      stripe_subscription_id: session.subscription,
      stripe_price_id: subscription.items.data.first.price.id,
      subscription_status: subscription.status,
      subscription_started_at: Time.at(subscription.current_period_start),
      subscription_ends_at: Time.at(subscription.current_period_end)
    )

    redirect_to plan_path, notice: "Subscription activated successfully!"
  rescue Stripe::InvalidRequestError
    redirect_to plan_path, alert: "Invalid session"
  end

  def cancel
    redirect_to plan_path, alert: "Checkout canceled."
  end

  def webhook
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      return head :bad_request
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    return unless session.metadata&.account_id

    account = Account.find_by(id: session.metadata.account_id)
    return unless account

    subscription = Stripe::Subscription.retrieve(session.subscription)

    account.update!(
      stripe_customer_id: session.customer,
      stripe_subscription_id: session.subscription,
      stripe_price_id: subscription.items.data.first.price.id,
      subscription_status: subscription.status,
      subscription_started_at: Time.at(subscription.current_period_start),
      subscription_ends_at: Time.at(subscription.current_period_end)
    )
  end

  def handle_subscription_updated(subscription)
    account = Account.find_by(stripe_subscription_id: subscription.id)
    return unless account

    account.update!(
      stripe_price_id: subscription.items.data.first.price.id,
      subscription_status: subscription.status,
      subscription_started_at: Time.at(subscription.current_period_start),
      subscription_ends_at: Time.at(subscription.current_period_end)
    )
  end

  def handle_subscription_deleted(subscription)
    account = Account.find_by(stripe_subscription_id: subscription.id)
    return unless account

    account.update!(subscription_status: "canceled")
  end
end
