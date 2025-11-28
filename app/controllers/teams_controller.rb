class TeamsController < ApplicationController
  before_action :authenticate_user!

  def show
    @memberships = current_account.memberships.includes(:user)
  end

  def update
    if current_account.update(team_params)
      redirect_to team_path, notice: "Team updated"
    else
      @memberships = current_account.memberships.includes(:user)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def team_params
    params.require(:account).permit(:name)
  end
end
