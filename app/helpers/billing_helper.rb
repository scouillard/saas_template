module BillingHelper
  def subscription_status_text(account)
    return "No Subscription" if account.subscription_status.blank?

    case account.subscription_status
    when "trialing" then trial_status_text(account)
    when "canceled" then canceled_status_text(account)
    else account.subscription_status.titleize
    end
  end

  private

  def trial_status_text(account)
    return "Trialing" if account.current_period_ends_at.blank?
    "Trial ends #{account.current_period_ends_at.strftime('%b %d, %Y')}"
  end

  def canceled_status_text(account)
    return "Canceled" unless account.current_period_ends_at&.> Time.current
    "Cancels #{account.current_period_ends_at.strftime('%b %d, %Y')}"
  end
end
