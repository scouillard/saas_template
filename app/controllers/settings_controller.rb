class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    if current_account.update(settings_params)
      redirect_to settings_path, notice: "Settings updated"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:account).permit
  end
end
