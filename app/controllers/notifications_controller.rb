class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def mark_all_seen
    current_user.notifications.unseen.update_all(seen_at: Time.current)
    head :ok
  end

  def mark_as_read
    notification = current_user.notifications.includes(:event).find(params[:id])
    notification.update(read_at: Time.current) if notification.unread?
    redirect_to notification.url
  end
end
