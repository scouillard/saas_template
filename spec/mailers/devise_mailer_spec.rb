require "rails_helper"

RSpec.describe "Devise confirmation email", type: :request do
  include ActionMailer::TestHelper

  describe "when user signs up" do
    it "sends a confirmation email" do
      expect {
        post user_registration_path, params: {
          user: { email: "new@example.com", password: "password123", password_confirmation: "password123" }
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "sends email to the correct address" do
      post user_registration_path, params: {
        user: { email: "test@example.com", password: "password123", password_confirmation: "password123" }
      }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq(%w[test@example.com])
    end

    it "has the correct subject" do
      post user_registration_path, params: {
        user: { email: "test@example.com", password: "password123", password_confirmation: "password123" }
      }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq("Confirmation instructions")
    end

    it "includes the user email in html body" do
      post user_registration_path, params: {
        user: { email: "test@example.com", password: "password123", password_confirmation: "password123" }
      }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.html_part.body.to_s).to include("test@example.com")
    end

    it "includes the user email in text body" do
      post user_registration_path, params: {
        user: { email: "test@example.com", password: "password123", password_confirmation: "password123" }
      }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.text_part.body.to_s).to include("test@example.com")
    end

    it "includes the confirmation link in html body" do
      post user_registration_path, params: {
        user: { email: "test@example.com", password: "password123", password_confirmation: "password123" }
      }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.html_part.body.to_s).to include("confirmation_token=")
    end

    it "includes the confirmation link in text body" do
      post user_registration_path, params: {
        user: { email: "test@example.com", password: "password123", password_confirmation: "password123" }
      }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.text_part.body.to_s).to include("confirmation_token=")
    end
  end

  describe "when registration fails" do
    it "does not send a confirmation email with invalid email" do
      expect {
        post user_registration_path, params: {
          user: { email: "invalid", password: "password123", password_confirmation: "password123" }
        }
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "does not send a confirmation email when passwords do not match" do
      expect {
        post user_registration_path, params: {
          user: { email: "test@example.com", password: "password123", password_confirmation: "different" }
        }
      }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
