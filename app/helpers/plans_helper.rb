module PlansHelper
  def format_plan_price(cents)
    return "Free" if cents.zero?
    dollars = cents / 100.0
    dollars == dollars.to_i ? "$#{dollars.to_i}" : "$#{'%.2f' % dollars}"
  end

  def annual_monthly_price(plan)
    plan.annual_price / 12
  end
end
