class Users::RegistrationsController < Devise::RegistrationsController
  rate_limit to: RateLimiting::REGISTRATION_LIMIT,
             within: RateLimiting::ONE_HOUR,
             only: :create

  before_action :configure_sign_up_params, only: [ :create ]

  def create
    @invitation = find_pending_invitation
    super
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  def build_resource(hash = {})
    super
    return unless @invitation

    resource.joining_via_invitation = true
    resource.email = @invitation.email
  end

  def after_sign_up_path_for(resource)
    if @invitation&.pending?
      @invitation.accept!(resource)
      session.delete(:invitation_token)
    end

    super
  end

  def after_inactive_sign_up_path_for(resource)
    if @invitation&.pending?
      @invitation.accept!(resource)
      session.delete(:invitation_token)
    end

    super
  end

  private

  def find_pending_invitation
    return unless session[:invitation_token].present?

    AccountInvitation.pending.find_by(token: session[:invitation_token])
  end
end
