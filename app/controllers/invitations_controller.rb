class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitation, only: :destroy

  def create
    email = params[:email]&.downcase&.strip

    if email.blank?
      redirect_to team_path, alert: "Email is required"
      return
    end

    if current_account.users.exists?(email: email)
      redirect_to team_path, alert: "This user is already a member of your team"
      return
    end

    if current_account.account_invitations.pending.exists?(email: email)
      redirect_to team_path, alert: "An invitation has already been sent to this email"
      return
    end

    invitation = current_account.account_invitations.build(
      email: email,
      inviter: current_user
    )

    if invitation.save
      AccountInvitationMailer.invite_email(invitation).deliver_later
      redirect_to team_path, notice: "Invitation sent to #{email}"
    else
      redirect_to team_path, alert: invitation.errors.full_messages.join(", ")
    end
  end

  def destroy
    @invitation.destroy
    redirect_to team_path, notice: "Invitation cancelled"
  end

  private

  def set_invitation
    @invitation = current_account.account_invitations.find(params[:id])
  end
end
