class PricingController < ApplicationController
  def index
    @plans = Plan.all
  end
end
