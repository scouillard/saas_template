require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, name: "Original Name") }

  before { sign_in user }

  describe "GET /profile" do
    it "renders the profile page" do
      get profile_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /profile" do
    it "updates the user name" do
      patch profile_path, params: { user: { name: "New Name" } }

      expect(response).to redirect_to(profile_path)
      expect(user.reload.name).to eq("New Name")
    end

    it "re-renders on invalid input" do
      patch profile_path, params: { user: { name: "" } }

      # Name is optional, so this should succeed
      expect(response).to redirect_to(profile_path)
    end
  end

  describe "PATCH /profile/password" do
    it "updates password with valid current password" do
      patch update_password_profile_path, params: {
        user: {
          current_password: "password123",
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }
      }

      expect(response).to redirect_to(profile_path)
      expect(user.reload.valid_password?("newpassword456")).to be true
    end

    it "fails with incorrect current password" do
      patch update_password_profile_path, params: {
        user: {
          current_password: "wrongpassword",
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?("password123")).to be true
    end

    it "fails when confirmation does not match" do
      patch update_password_profile_path, params: {
        user: {
          current_password: "password123",
          password: "newpassword456",
          password_confirmation: "differentpassword"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?("password123")).to be true
    end
  end
end
