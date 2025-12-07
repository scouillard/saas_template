class BillingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @account = current_account
    @current_plan = Plan.find_by(id: @account.plan)
  end
end
