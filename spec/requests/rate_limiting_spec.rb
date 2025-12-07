# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate Limiting", type: :request do
  before do
    Rails.cache.clear
  end

  describe "User Registration" do
    it "blocks requests exceeding the rate limit (5 per hour)" do
      6.times do
        post user_registration_path, params: {
          user: { email: Faker::Internet.email, password: "password123", name: "Test" }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Password Reset" do
    it "blocks requests exceeding the rate limit (3 per hour)" do
      4.times do
        post user_password_path, params: {
          user: { email: Faker::Internet.email }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Contact Form" do
    it "blocks requests exceeding the rate limit (3 per 10 minutes)" do
      4.times do
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
    it "blocks requests exceeding the rate limit (2 per hour)" do
      3.times do
        post subscribe_path, params: {
          subscriber: { email: Faker::Internet.email }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
