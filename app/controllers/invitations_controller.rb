class InvitationsController < ApplicationController
  before_action :authenticate_user!

  def create
    @invitation = current_account.account_invitations.build(invitation_params)
    @invitation.invited_by = current_user

    if @invitation.save
      AccountInvitationMailer.invite(@invitation).deliver_later
      redirect_to team_path, notice: "Invitation sent to #{@invitation.email}"
    else
      redirect_to team_path, alert: @invitation.errors.full_messages.to_sentence
    end
  end

  def destroy
    @invitation = current_account.account_invitations.find(params[:id])
    @invitation.destroy
    redirect_to team_path, notice: "Invitation cancelled"
  end

  private

  def invitation_params
    params.permit(:email)
  end
end
