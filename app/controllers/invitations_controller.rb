class InvitationsController < ApplicationController
  before_action :authenticate_user!

  def create
    # TODO: Implement when Invitation model is added
    redirect_to team_path, notice: "Invitation sent"
  end

  def destroy
    # TODO: Implement when Invitation model is added
    redirect_to team_path, notice: "Invitation cancelled"
  end
end
