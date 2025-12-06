class AccountInvitationsController < ApplicationController
  rate_limit to: RateLimiting::INVITATION_CREATE_LIMIT,
             within: RateLimiting::ONE_HOUR,
             by: -> { rate_limit_key },
             only: :create

  rate_limit to: RateLimiting::INVITATION_ACCEPT_LIMIT,
             within: RateLimiting::ONE_HOUR,
             only: :accept

  before_action :authenticate_user!, only: [ :create, :destroy ]
  before_action :set_invitation, only: [ :show, :accept ]
  before_action :redirect_if_signed_in_with_different_email, only: [ :show, :accept ]

  # GET /invitations/:token
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

  # POST /invitations/:token/accept
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

  # POST /invitations
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

  # DELETE /invitations/:id
  def destroy
    @invitation = current_account.account_invitations.find(params[:id])
    @invitation.destroy
    redirect_to team_path, notice: "Invitation cancelled"
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

  def invitation_params
    params.permit(:email)
  end
end
