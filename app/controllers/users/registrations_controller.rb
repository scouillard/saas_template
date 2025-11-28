class Users::RegistrationsController < Devise::RegistrationsController
  def new
    @invitation_token = params[:invitation_token]
    if @invitation_token.present?
      @invitation = AccountInvitation.find_by(token: @invitation_token)
      if @invitation.nil? || @invitation.accepted? || @invitation.expired?
        redirect_to root_path, alert: "Invalid or expired invitation"
        return
      end
    end
    super
  end

  def create
    @invitation_token = params[:user][:invitation_token]
    @invitation = AccountInvitation.find_by(token: @invitation_token) if @invitation_token.present?

    build_resource(sign_up_params)

    if @invitation.present? && @invitation.pending? && resource.email.downcase == @invitation.email.downcase
      resource.invitation_token = @invitation_token
    end

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if @invitation.present? && @invitation.pending? && resource.email.downcase == @invitation.email.downcase
        @invitation.accept!(resource)
      end

      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :invitation_token)
  end
end
