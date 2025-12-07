class BillingController < ApplicationController
  before_action :authenticate_user!

  def show
    unless current_account.stripe_customer_id
      redirect_to plan_path, alert: "No billing information found"
      return
    end

    session = Stripe::BillingPortal::Session.create(
      customer: current_account.stripe_customer_id,
      return_url: plan_url
    )

    redirect_to session.url, allow_other_host: true
  end
end
