class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_account

  private

  def current_account
    return nil unless current_user

    @current_account ||= current_user.accounts.first
  end

  def after_sign_in_path_for(_resource)
    root_path
  end
end
