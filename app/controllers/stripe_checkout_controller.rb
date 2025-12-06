class StripeCheckoutController < ApplicationController
  before_action :authenticate_user!

  def create
    plan = Plan.find(params[:plan])
    interval = params[:interval]

    unless %w[monthly annual].include?(interval)
      redirect_to pricing_path, alert: "Invalid billing interval" and return
    end

    price_id = interval == "monthly" ? plan.stripe_monthly_price_id : plan.stripe_annual_price_id

    if price_id.blank?
      redirect_to pricing_path, alert: "This plan is not available for purchase" and return
    end

    session = create_checkout_session(plan, price_id)
    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  private

  def create_checkout_session(plan, price_id)
    session_params = {
      line_items: [ { price: price_id, quantity: 1 } ],
      mode: "subscription",
      success_url: checkout_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: pricing_url,
      allow_promotion_codes: true,
      automatic_tax: { enabled: true }
    }

    if current_account.stripe_customer_id.present?
      session_params[:customer] = current_account.stripe_customer_id
    else
      session_params[:customer_email] = current_user.email
    end

    if plan.trial_days.present?
      session_params[:subscription_data] = { trial_period_days: plan.trial_days }
    end

    Stripe::Checkout::Session.create(session_params)
  end
end
