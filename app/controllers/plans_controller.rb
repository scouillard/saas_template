class PlansController < ApplicationController
  before_action :authenticate_user!, only: :show

  def index
    @plans = Plan.all
  end

  def show
  end
end
