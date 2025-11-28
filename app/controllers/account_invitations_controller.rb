class AccountInvitationsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    @invitation = current_account.invitations.build(invitation_params)
    @invitation.inviter = current_user

    if @invitation.save
      AccountInvitationMailer.invite(@invitation).deliver_later
      redirect_to team_path, notice: "Invitation sent to #{@invitation.email}"
    else
      redirect_to team_path, alert: @invitation.errors.full_messages.to_sentence
    end
  end

  def accept
    @invitation = AccountInvitation.find_by(token: params[:token])

    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired"
    elsif @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted"
    elsif user_signed_in?
      accept_for_signed_in_user
    else
      store_invitation_token_and_redirect_to_signup
    end
  end

  private

  def invitation_params
    params.permit(:email)
  end

  def accept_for_signed_in_user
    if current_user.accounts.include?(@invitation.account)
      redirect_to root_path, notice: "You're already a member of this team"
    else
      @invitation.accept!(current_user)
      redirect_to root_path, notice: "You've joined #{@invitation.account.name}!"
    end
  end

  def store_invitation_token_and_redirect_to_signup
    session[:invitation_token] = @invitation.token
    redirect_to new_user_registration_path
  end
end
