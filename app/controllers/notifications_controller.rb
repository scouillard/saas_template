class NotificationsController < ApplicationController
  rate_limit to: RateLimiting::NOTIFICATION_LIMIT,
             within: RateLimiting::ONE_MINUTE,
             by: -> { rate_limit_key },
             only: :mark_all_seen

  before_action :authenticate_user!

  def mark_all_seen
    current_user.notifications.unseen.update_all(seen_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    head :ok
  end

  def mark_as_read
    notification = current_user.notifications.includes(:event).find(params[:id])
    notification.update(read_at: Time.current) if notification.unread?
    redirect_to notification.url
  end
end
