class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def cancel
    unless current_account.subscription_active?
      redirect_to plan_path, alert: "No active subscription to cancel"
      return
    end

    @current_period_ends_at = current_account.current_period_ends_at
  end

  def portal
    unless current_account.stripe_customer_id.present?
      redirect_to plan_path, alert: "No billing information found"
      return
    end

    session = Stripe::BillingPortal::Session.create(
      customer: current_account.stripe_customer_id,
      return_url: plan_url
    )

    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  def reactivate
    unless current_account.can_reactivate?
      redirect_to plan_path, alert: "Cannot reactivate subscription"
      return
    end

    Stripe::Subscription.update(
      current_account.stripe_subscription_id,
      cancel_at_period_end: false
    )

    current_account.update!(subscription_status: :active)

    redirect_to plan_path, notice: "Your subscription has been reactivated"
  end
end
