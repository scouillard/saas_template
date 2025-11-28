class AccountInvitationsController < ApplicationController
  def show
    @invitation = AccountInvitation.find_by(token: params[:token])

    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
    elsif @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted"
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired"
    elsif user_signed_in?
      if current_user.email.downcase == @invitation.email.downcase
        @invitation.accept!(current_user)
        redirect_to root_path, notice: "You've joined #{@invitation.account.name}"
      else
        redirect_to root_path, alert: "This invitation was sent to a different email address"
      end
    else
      redirect_to new_user_registration_path(invitation_token: @invitation.token)
    end
  end
end
