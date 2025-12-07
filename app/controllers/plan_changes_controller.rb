class PlanChangesController < ApplicationController
  # Security: limit plan change session creation (10 per 5 minutes)
  rate_limit to: 10, within: 5.minutes, only: :create

  before_action :authenticate_user!
  before_action :require_active_subscription, only: [ :new, :create ]
  before_action :set_plans, only: [ :new ]
  before_action :set_target_plan, only: [ :new, :create ]
  before_action :validate_plan_change, only: [ :new, :create ]

  def new
    @current_plan = current_account.current_plan
    @interval = params[:interval] || "monthly"
    @change_type = current_account.upgrading_to?(@target_plan.id) ? :upgrade : :downgrade
  end

  def create
    interval = params[:interval]
    unless %w[monthly annual].include?(interval)
      redirect_to new_plan_change_path(plan: @target_plan.id), alert: "Invalid billing interval" and return
    end

    price_id = interval == "monthly" ? @target_plan.stripe_monthly_price_id : @target_plan.stripe_annual_price_id
    if price_id.blank?
      redirect_to new_plan_change_path(plan: @target_plan.id), alert: "This plan is not available" and return
    end

    session = create_plan_change_session(@target_plan, price_id, interval)
    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  private

  def require_active_subscription
    return if current_account&.can_change_plan?

    redirect_to pricing_path, alert: "You need an active subscription to change plans"
  end

  def set_plans
    @plans = Plan.all
  end

  def set_target_plan
    @target_plan = Plan.find_by(id: params[:plan])
    redirect_to plan_path, alert: "Plan not found" unless @target_plan
  end

  def validate_plan_change
    return unless @target_plan
    return unless @target_plan.id == current_account.plan

    redirect_to plan_path, alert: "You're already on this plan"
  end

  def create_plan_change_session(plan, price_id, interval)
    session_params = {
      customer: current_account.stripe_customer_id,
      line_items: [ { price: price_id, quantity: 1 } ],
      mode: "subscription",
      success_url: checkout_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: new_plan_change_url(plan: plan.id, interval: interval),
      allow_promotion_codes: true,
      automatic_tax: { enabled: true }
    }

    change_type = current_account.upgrading_to?(plan.id) ? :upgrade : :downgrade

    if change_type == :upgrade
      session_params[:subscription_data] = { proration_behavior: "create_prorations" }
    end

    Stripe::Checkout::Session.create(session_params)
  end
end
