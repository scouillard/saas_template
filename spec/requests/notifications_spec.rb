require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }

  before do
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  describe "POST /notifications/mark_all_seen" do
    it "marks all unseen notifications as seen" do
      expect(user.notifications.unseen.count).to eq(1)

      post mark_all_seen_notifications_path

      expect(response).to have_http_status(:ok)
      expect(user.notifications.unseen.count).to eq(0)
      expect(user.notifications.seen.count).to eq(1)
    end

    it "does not mark notifications as read" do
      post mark_all_seen_notifications_path

      expect(user.notifications.unread.count).to eq(1)
    end
  end

  describe "POST /notifications/:id/read" do
    let(:notification) { user.notifications.first }

    it "marks the notification as read" do
      expect(notification.unread?).to be true

      post read_notification_path(notification)

      expect(notification.reload.read?).to be true
    end

    it "redirects to the notification url" do
      post read_notification_path(notification)

      expect(response).to redirect_to(root_path)
    end

    it "does not mark other notifications as read" do
      WelcomeNotifier.deliver(user)
      other_notification = user.notifications.last

      post read_notification_path(notification)

      expect(other_notification.reload.unread?).to be true
    end
  end
end
