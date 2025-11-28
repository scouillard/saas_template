class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def edit_password
  end

  def update_password
    if current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to profile_path, notice: "Password updated"
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.sole_owner_of_multi_member_account?
      redirect_to profile_path, alert: "You must transfer ownership before deleting your account"
      return
    end

    current_user.destroy
    redirect_to root_path, notice: "Your account has been deleted"
  end

  private

  def profile_params
    params.require(:user).permit(:name)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
