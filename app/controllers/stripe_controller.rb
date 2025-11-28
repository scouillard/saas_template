class StripeController < ApplicationController
  before_action :authenticate_user!, except: :webhook
  skip_before_action :verify_authenticity_token, only: :webhook

  def checkout
    price_id = params[:price_id]
    return redirect_to plan_path, alert: "Invalid price" if price_id.blank?

    customer_id = current_account.create_stripe_customer(current_user)

    session = Stripe::Checkout::Session.create(
      customer: customer_id,
      mode: "subscription",
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: stripe_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: stripe_cancel_url,
      metadata: { account_id: current_account.id }
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    subscription = Stripe::Subscription.retrieve(session.subscription)

    current_account.update!(
      stripe_subscription_id: subscription.id,
      stripe_price_id: subscription.items.data.first.price.id,
      subscription_status: :active,
      subscription_started_at: Time.zone.at(subscription.current_period_start),
      subscription_ends_at: Time.zone.at(subscription.current_period_end),
      plan: plan_from_price_id(subscription.items.data.first.price.id)
    )

    redirect_to plan_path, notice: "Subscription activated successfully!"
  end

  def cancel
    redirect_to plan_path, notice: "Checkout was canceled."
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

    handle_event(event)
    head :ok
  end

  private

  def handle_event(event)
    case event.type
    when "customer.subscription.created", "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    when "invoice.payment_failed"
      handle_payment_failed(event.data.object)
    end
  end

  def handle_subscription_updated(subscription)
    account = Account.find_by(stripe_customer_id: subscription.customer)
    return unless account

    account.update!(
      stripe_subscription_id: subscription.id,
      stripe_price_id: subscription.items.data.first.price.id,
      subscription_status: subscription.status == "active" ? :active : :past_due,
      subscription_started_at: Time.zone.at(subscription.current_period_start),
      subscription_ends_at: Time.zone.at(subscription.current_period_end),
      plan: plan_from_price_id(subscription.items.data.first.price.id)
    )
  end

  def handle_subscription_deleted(subscription)
    account = Account.find_by(stripe_customer_id: subscription.customer)
    return unless account

    account.update!(
      subscription_status: :canceled,
      plan: :free
    )
  end

  def handle_payment_failed(invoice)
    account = Account.find_by(stripe_customer_id: invoice.customer)
    return unless account

    account.update!(subscription_status: :past_due)
  end

  def plan_from_price_id(price_id)
    case price_id
    when ENV["STRIPE_PRO_PRICE_ID"]
      :pro
    when ENV["STRIPE_BUSINESS_PRICE_ID"]
      :business
    else
      :free
    end
  end
end
