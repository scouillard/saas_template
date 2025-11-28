class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: :create

  def new
    build_resource
    resource.invitation_token = session[:invitation_token]
    yield resource if block_given?
    respond_with resource
  end

  def create
    super do |resource|
      if resource.persisted? && session[:invitation_token].present?
        session.delete(:invitation_token)
      end
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :invitation_token ])
  end

  def build_resource(hash = nil)
    super
    resource.invitation_token ||= session[:invitation_token]
  end
end
