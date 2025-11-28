class InvitationAcceptancesController < ApplicationController
  before_action :set_invitation, only: [ :show, :accept ]
  before_action :redirect_if_signed_in_with_different_email, only: [ :show, :accept ]

  def show
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired"
    elsif @invitation.accepted?
      redirect_to root_path, notice: "This invitation has already been accepted"
    else
      store_invitation_token
    end
  end

  def accept
    if @invitation.nil? || !@invitation.pending?
      redirect_to root_path, alert: "Invalid or expired invitation"
      return
    end

    if user_signed_in?
      accept_for_current_user
    else
      redirect_to new_user_registration_path
    end
  end

  private

  def set_invitation
    @invitation = AccountInvitation.find_by(token: params[:token])
  end

  def redirect_if_signed_in_with_different_email
    return unless user_signed_in? && @invitation&.pending?
    return if current_user.email.downcase == @invitation.email.downcase

    redirect_to root_path, alert: "This invitation was sent to a different email address"
  end

  def accept_for_current_user
    if @invitation.accept!(current_user)
      clear_invitation_token
      redirect_to root_path, notice: "You have joined #{@invitation.account.name}"
    else
      redirect_to root_path, alert: "Unable to accept invitation"
    end
  end

  def store_invitation_token
    session[:invitation_token] = @invitation.token
  end

  def clear_invitation_token
    session.delete(:invitation_token)
  end
end
