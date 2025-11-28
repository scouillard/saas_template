class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.find_or_create_from_oauth(auth)

    if user.persisted?
      sign_in user

      redirect_to after_sign_in_path_for(user)
    else
      redirect_to new_user_session_path, alert: "Authentication failed. Please try again."
    end
  end

  def failure
    redirect_to new_user_session_path, alert: "Authentication failed: #{params[:message]}"
  end

  private

  def auth
    request.env["omniauth.auth"]
  end
end
