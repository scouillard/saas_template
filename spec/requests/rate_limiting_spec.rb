# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate Limiting", type: :request do
  before do
    Rails.cache.clear
  end

  describe "User Registration" do
    it "allows requests within the rate limit" do
      RateLimiting::REGISTRATION_LIMIT.times do
        post user_registration_path, params: {
          user: { email: Faker::Internet.email, password: "password123", name: "Test" }
        }
      end

      # All requests should go through (not 429)
      expect(response.status).not_to eq(429)
    end

    it "blocks requests exceeding the rate limit" do
      (RateLimiting::REGISTRATION_LIMIT + 1).times do
        post user_registration_path, params: {
          user: { email: Faker::Internet.email, password: "password123", name: "Test" }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Password Reset" do
    it "blocks requests exceeding the rate limit" do
      (RateLimiting::PASSWORD_RESET_LIMIT + 1).times do
        post user_password_path, params: {
          user: { email: Faker::Internet.email }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Contact Form" do
    it "allows requests within the rate limit" do
      RateLimiting::CONTACT_FORM_LIMIT.times do
        post contact_path, params: {
          contact_message: {
            name: "Test User",
            email: Faker::Internet.email,
            title: "Test Subject",
            message: "Test message"
          }
        }
      end

      expect(response.status).not_to eq(429)
    end

    it "blocks requests exceeding the rate limit" do
      (RateLimiting::CONTACT_FORM_LIMIT + 1).times do
        post contact_path, params: {
          contact_message: {
            name: "Test User",
            email: Faker::Internet.email,
            title: "Test Subject",
            message: "Test message"
          }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Newsletter Subscription" do
    it "blocks requests exceeding the rate limit" do
      (RateLimiting::NEWSLETTER_LIMIT + 1).times do
        post subscribe_path, params: {
          subscriber: { email: Faker::Internet.email }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Profile Updates" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "allows requests within the rate limit" do
      RateLimiting::PROFILE_UPDATE_LIMIT.times do
        patch profile_path, params: { user: { name: "New Name" } }
      end

      expect(response.status).not_to eq(429)
    end

    it "blocks requests exceeding the rate limit" do
      (RateLimiting::PROFILE_UPDATE_LIMIT + 1).times do
        patch profile_path, params: { user: { name: "New Name" } }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Notifications Mark All Seen" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "blocks requests exceeding the rate limit" do
      (RateLimiting::NOTIFICATION_LIMIT + 1).times do
        post mark_all_seen_notifications_path
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
