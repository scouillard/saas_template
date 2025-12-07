class BillingPortalController < ApplicationController
  before_action :authenticate_user!
  before_action :require_stripe_customer

  def create
    session = Stripe::BillingPortal::Session.create({
      customer: current_account.stripe_customer_id,
      return_url: billing_url
    })

    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  private

  def require_stripe_customer
    return if current_account&.stripe_customer_id.present?

    redirect_to billing_path, alert: "Please subscribe to a plan first"
  end
end
