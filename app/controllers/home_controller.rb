class HomeController < ApplicationController
  def index
    @plans = Plan.all
  end

  def privacy
  end

  def terms
  end
end
