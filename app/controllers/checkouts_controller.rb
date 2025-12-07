class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_session_id, only: :success
  before_action :require_current_account, only: :success

  def success
    session = retrieve_stripe_session(params[:session_id])
    return redirect_to pricing_path, alert: "Checkout session not found" unless session
    return redirect_to pricing_path, alert: "Payment incomplete. Please try again." unless session.status == "complete"
    return redirect_to root_path, notice: "Subscription already active" if already_processed?(session)

    update_account_subscription(session)
    @subscription = session.subscription
    @plan = Plan.find_by(id: current_account.plan)
    @interval = @subscription.items.data.first.price.recurring.interval
    render "checkout_success/show"
  end

  private

  def require_session_id
    redirect_to pricing_path, alert: "Invalid checkout session" unless params[:session_id].present?
  end

  def require_current_account
    redirect_to root_path, alert: "Account not found" unless current_account
  end

  def retrieve_stripe_session(session_id)
    Stripe::Checkout::Session.retrieve(session_id, expand: [ "subscription", "customer" ])
  rescue Stripe::InvalidRequestError
    nil
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe error: #{e.message}")
    nil
  end

  def already_processed?(session)
    current_account.stripe_subscription_id == session.subscription&.id
  end

  def update_account_subscription(session)
    subscription = session.subscription
    current_account.update!(subscription_attributes(session, subscription))
  end

  def subscription_attributes(session, subscription)
    {
      stripe_customer_id: extract_customer_id(session),
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      plan: determine_plan_from_price_id(subscription.items.data.first.price.id),
      subscription_started_at: Time.zone.at(subscription.created),
      current_period_ends_at: Time.zone.at(subscription.current_period_end)
    }
  end

  def extract_customer_id(session)
    session.customer.is_a?(String) ? session.customer : session.customer.id
  end

  def determine_plan_from_price_id(price_id)
    Plan.all.find { |p| [ p.stripe_monthly_price_id, p.stripe_annual_price_id ].include?(price_id) }&.id || "free"
  end
end
