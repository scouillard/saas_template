class CheckoutSuccessController < ApplicationController
  before_action :authenticate_user!

  def show
    @session = Stripe::Checkout::Session.retrieve(
      params[:session_id],
      expand: [ "subscription" ]
    )
    @subscription = @session.subscription
    @plan = find_plan_by_price_id(@subscription.items.data.first.price.id)
    @interval = @subscription.items.data.first.price.recurring.interval
  rescue Stripe::InvalidRequestError
    redirect_to pricing_path, alert: "Session not found"
  end

  private

  def find_plan_by_price_id(price_id)
    Plan.all.find do |plan|
      plan.stripe_monthly_price_id == price_id || plan.stripe_annual_price_id == price_id
    end
  end
end
